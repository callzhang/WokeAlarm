//
//  TICDSSynchronizedManagedObject.m
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

#import "TMSynchronizedManagedObject.h"
#import "CocoaLumberjack.h"
#import "TMCoreDataSyncManager.h"
#import "NSManagedObjectContext+TMKitAddition.h"
#import "TMSyncChangeObject.h"
#import "TMChangeIntegrityStoreManager.h"
#import "TMCoreDataConstants.h"

@implementation TMSynchronizedManagedObject
@dynamic tmSyncID;

#pragma mark - Primary Sync Change Creation

+ (NSSet *)keysForWhichSyncChangesWillNotBeCreated {
    return nil;
}

- (void)createSyncChangeToSyncManagedContext:(NSManagedObjectContext *)syncManagedContext {
    // if not in a synchronized MOC, or we don't have a doc sync manager, exit now
    if (syncManagedContext.isSynchronized == NO || syncManagedContext.documentSyncManager == nil) {
        if (syncManagedContext.isSynchronized == NO) {
            DDLogError(@"Skipping sync change creation for %@ because our managedObjectContext is not marked as synchronized.", [self class]);
        }

        if (syncManagedContext.documentSyncManager == nil) {
            DDLogError(@"Skipping sync change creation for %@ because our managedObjectContext has no documentSyncManager.", [self class]);
        }

        return;
    }

    if ( [self isInserted] ) {
        [self createSyncChangeForInsertionToSyncManagedContext:syncManagedContext];
    }

    if ( [self isUpdated] ) {
        [self createSyncChangesForChangedPropertiesToSyncManagedContext:syncManagedContext];
    }

    if ( [self isDeleted] ) {
        [self createSyncChangeForDeletionToSyncManagedContext:syncManagedContext];
    }
}

- (void)createSyncChangeForInsertionToSyncManagedContext:(NSManagedObjectContext *)syncManagedContext {
    // changedAttributes = a dictionary containing the values of _all_ the object's attributes at time it was saved
    // this method also creates extra sync changes for _all_ the object's relationships

    if ([TMChangeIntegrityStoreManager containsInsertionRecordForSyncID:self.tmSyncID]) {
        [TMChangeIntegrityStoreManager removeSyncIDFromInsertionIntegrityStore:self.tmSyncID];
        return;
    }

    [TMChangeIntegrityStoreManager storeTICDSSyncID:self.tmSyncID forManagedObjectID:self.objectID];

    TMSyncChangeObject *syncChange = [self createSyncChangeForChangeType:TMSyncChangeTypeObjectInserted inManagedObjectContext:syncManagedContext];

    DDLogVerbose(@"[%@] %@", syncChange.objectSyncID, [self class]);

    [syncChange setChangedAttributes:[self dictionaryOfAllAttributes]];
    [self createSyncChangesForAllRelationshipsInManagedObjectContext:syncManagedContext];
}

- (void)createSyncChangeForDeletionToSyncManagedContext:(NSManagedObjectContext *)syncManagedContext {
    if ([TMChangeIntegrityStoreManager containsDeletionRecordForSyncID:self.tmSyncID]) {
        [TMChangeIntegrityStoreManager removeSyncIDFromDeletionIntegrityStore:self.tmSyncID];
        return;
    }

    // nothing is stored in changedAttributes or changedRelationships at this time
    // if a conflict is encountered, the deletion will have to take precedent, resurrection is not possible
    [self createSyncChangeForChangeType:TMSyncChangeTypeObjectDeleted inManagedObjectContext:syncManagedContext];
}

- (void)createSyncChangesForChangedPropertiesToSyncManagedContext:(NSManagedObjectContext *)syncManagedConext {
    // separate sync changes are created for each property change, whether it be relationship or attribute
    NSDictionary *changedValues = [self changedValues];

    NSSet *propertyNamesToBeIgnored = [[self class] keysForWhichSyncChangesWillNotBeCreated];
    for( NSString *eachPropertyName in changedValues ) {
        if (propertyNamesToBeIgnored != nil && [propertyNamesToBeIgnored containsObject:eachPropertyName]) {
            DDLogVerbose(@"Not creating a change for %@.%@", [self class], eachPropertyName);
            continue;
        }

        id eachValue = [changedValues valueForKey:eachPropertyName];

        NSRelationshipDescription *relationshipDescription = [[[self entity] relationshipsByName] valueForKey:eachPropertyName];
        if( relationshipDescription ) {
            [self createSyncChangeIfApplicableForRelationship:relationshipDescription inManagedObjectContext:syncManagedConext];
        }
        else {
            if ([TMChangeIntegrityStoreManager containsChangedAttributeRecordForKey:eachPropertyName withValue:eachValue syncID:self.tmSyncID]) {
                continue;
            }

            TMSyncChangeObject *syncChange = [self createSyncChangeForChangeType:TMSyncChangeTypeAttributeChanged inManagedObjectContext:syncManagedConext];
            DDLogVerbose(@"[%@] %@", syncChange.objectSyncID, [self class]);
            [syncChange setRelevantKey:eachPropertyName];
            [syncChange setChangedAttributes:eachValue];
        }
    }

    [TMChangeIntegrityStoreManager removeChangedAttributesEntryFromChangeIntegrityStoreForSyncID:self.tmSyncID];
}

#pragma mark - Sync Change Helper Methods

- (TMSyncChangeObject *)createSyncChangeForChangeType:(TMSyncChangeType)aType inManagedObjectContext:(NSManagedObjectContext *)context {
    TMSyncChangeObject *syncChange = [TMSyncChangeObject createdSyncChangeOfType:aType inManagedObjectContext:context];

    NSString *syncID = self.tmSyncID;
    if ([syncID length] == 0) {
        syncID = [TMChangeIntegrityStoreManager ticdsSyncIDForManagedObjectID:self.objectID];
    }

    [syncChange setObjectSyncID:syncID];
    [syncChange setObjectEntityName:[[self entity] name]];
    [syncChange setLocalTimeStamp:[NSDate date]];
    [syncChange setRelevantManagedObject:self];

    DDLogVerbose(@"[%@] %@", syncChange.objectSyncID, [self class]);
    return syncChange;
}

- (void)createSyncChangesForAllRelationshipsInManagedObjectContext:(NSManagedObjectContext *)context {
    NSDictionary *objectRelationshipsByName = [[self entity] relationshipsByName];

    for( NSString *eachRelationshipName in objectRelationshipsByName ) {
        [self createSyncChangeIfApplicableForRelationship:[objectRelationshipsByName valueForKey:eachRelationshipName] inManagedObjectContext:context];
    }
}

- (void)createSyncChangeIfApplicableForRelationship:(NSRelationshipDescription *)aRelationship inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSRelationshipDescription *inverseRelationship = [aRelationship inverseRelationship];

    // Each check makes sure there _is_ an inverse relationship before checking its type, to allow for relationships with no inverse set

    // Check if this is a many-to-one relationship (only sync the -to-one side)
    if( ([aRelationship isToMany]) && inverseRelationship && ([inverseRelationship isToMany] == NO) ) {
        return;
    }

    // Check if this is a many to many relationship, and only sync the first relationship name alphabetically
    if( ([aRelationship isToMany]) && inverseRelationship && ([inverseRelationship isToMany]) && ([[aRelationship name] caseInsensitiveCompare:[inverseRelationship name]] == NSOrderedDescending) ) {
        return;
    }

    // Check if this is a one to one relationship, and only sync the first relationship name alphabetically
    if( ([aRelationship isToMany] == NO) && inverseRelationship && ([inverseRelationship isToMany] == NO) && ([[aRelationship name] caseInsensitiveCompare:[inverseRelationship name]] == NSOrderedDescending) ) {
        return;
    }

    // Check if this is a self-referential relationship, and only sync one side, somehow!!!

    // If we get here, this is:
    // a) a one-to-many relationship
    // b) the alphabetically lower end of a many-to-many relationship
    // c) the alphabetically lower end of a one-to-one relationship
    // d) edge-case 1: a many-to-many relationship with the same relationship name at both ends (will currently create 2 sync changes)
    // e) edge-case 2: a one-to-one relationship with the same relationship name at both ends (will currently create 2 sync changes)

    if ([aRelationship isToMany]) {
        [self createToManyRelationshipSyncChanges:aRelationship inManagedObjectContext:context];
    } else {
        [self createToOneRelationshipSyncChange:aRelationship inManagedObjectContext:context];
    }
}

- (void)createToOneRelationshipSyncChange:(NSRelationshipDescription *)aRelationship inManagedObjectContext:(NSManagedObjectContext *)context {
    NSString *relevantKey = [aRelationship name];
    NSManagedObject *relatedObject = [self valueForKey:relevantKey];

    // Check that the related object should be synchronized
    if (relatedObject != nil && [relatedObject isKindOfClass:[TMSynchronizedManagedObject class]] == NO) {
        return;
    }

    NSString *relatedObjectEntityName = [[aRelationship destinationEntity] name];
    NSString *relatedObjectSyncID = [relatedObject valueForKey:TMSyncIDAttributeName];

    if ([TMChangeIntegrityStoreManager containsChangedAttributeRecordForKey:relevantKey withValue:relatedObjectSyncID syncID:self.tmSyncID]) {
        return;
    }

    TMSyncChangeObject *syncChange = [self createSyncChangeForChangeType:TMSyncChangeTypeToOneRelationshipChanged inManagedObjectContext:context];
    [syncChange setRelatedObjectEntityName:relatedObjectEntityName];
    [syncChange setRelevantKey:relevantKey];
    [syncChange setChangedRelationships:relatedObjectSyncID];

    DDLogVerbose(@"[%@] %@", syncChange.objectSyncID, [self class]);
}

- (void)createToManyRelationshipSyncChanges:(NSRelationshipDescription *)aRelationship inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSSet *relatedObjects = [self valueForKey:[aRelationship name]];
    NSDictionary *committedValues = [self committedValuesForKeys:[NSArray arrayWithObject:[aRelationship name]]];

    NSSet *previouslyRelatedObjects = [committedValues valueForKey:[aRelationship name]];

    NSMutableSet *addedObjects = [NSMutableSet setWithCapacity:5];
    for( NSManagedObject *eachObject in relatedObjects ) {
        if( ![previouslyRelatedObjects containsObject:eachObject] ) {
            [addedObjects addObject:eachObject];
        }
    }

    NSMutableSet *removedObjects = [NSMutableSet setWithCapacity:5];
    for( NSManagedObject *eachObject in previouslyRelatedObjects ) {
        if( ![relatedObjects containsObject:eachObject] ) {
            [removedObjects addObject:eachObject];
        }
    }

    TMSyncChangeObject *eachChange = nil;

    for( NSManagedObject *eachObject in addedObjects ) {
        if ([eachObject isKindOfClass:[TMSynchronizedManagedObject class]] == NO) {
            continue;
        }

        NSString *relevantKey = [aRelationship name];
        NSString *relatedObjectSyncID = [eachObject valueForKey:TMSyncIDAttributeName];

        if ([TMChangeIntegrityStoreManager containsChangedAttributeRecordForKey:relevantKey withValue:relatedObjectSyncID syncID:self.tmSyncID]) {
            continue;
        }

        eachChange = [self createSyncChangeForChangeType:TMSyncChangeTypeToManyRelationshipChangedByAddingObject inManagedObjectContext:context];

        DDLogVerbose(@"[%@] %@", eachChange.objectSyncID, [self class]);

        [eachChange setRelatedObjectEntityName:[[aRelationship destinationEntity] name]];
        [eachChange setRelevantKey:relevantKey];
        [eachChange setChangedRelationships:relatedObjectSyncID];
    }

    for( NSManagedObject *eachObject in removedObjects ) {
        if ([eachObject isKindOfClass:[TMSynchronizedManagedObject class]] == NO) {
            continue;
        }

        NSString *relevantKey = [aRelationship name];
        NSString *relatedObjectSyncID = [eachObject valueForKey:TMSyncIDAttributeName];

        if ([TMChangeIntegrityStoreManager containsChangedAttributeRecordForKey:relevantKey withValue:relatedObjectSyncID syncID:self.tmSyncID]) {
            continue;
        }

        eachChange = [self createSyncChangeForChangeType:TMSyncChangeTypeToManyRelationshipChangedByRemovingObject inManagedObjectContext:context];

        DDLogVerbose(@"[%@] %@", eachChange.objectSyncID, [self class]);

        [eachChange setRelatedObjectEntityName:[[aRelationship destinationEntity] name]];
        [eachChange setRelevantKey:relevantKey];
        [eachChange setChangedRelationships:relatedObjectSyncID];
    }
}

#pragma mark - Dictionaries

- (NSDictionary *)dictionaryOfAllAttributes {
    NSDictionary *objectAttributeNames = [[self entity] attributesByName];

    NSMutableDictionary *attributeValues = [NSMutableDictionary dictionaryWithCapacity:[objectAttributeNames count]];
    for( NSString *eachAttributeName in [objectAttributeNames allKeys] ) {
        [attributeValues setValue:[self valueForKey:eachAttributeName] forKey:eachAttributeName];
    }

    return attributeValues;
}

#pragma mark - Managed Object Lifecycle

- (void)awakeFromInsert {
    [super awakeFromInsert];

    [self setValue:[[NSProcessInfo processInfo] globallyUniqueString] forKey:TMSyncIDAttributeName];
}

#pragma mark - Properties

//- (NSManagedObjectContext *)syncChangesMOC
//{
//    TICDSDocumentSyncManager *documentSyncManager = self.managedObjectContext.documentSyncManager;
//    if (documentSyncManager == nil) {
//        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Could not return a syncChangesMOC from %@ because our managedObjectContext has no documentSyncManager.", [self class]);
//        return nil;
//    }
//    
//    return [documentSyncManager syncChangesMocForDocumentMoc:self.managedObjectContext];
//}


@end
