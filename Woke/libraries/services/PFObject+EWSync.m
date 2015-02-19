//
//  PFObject+EWSync.m
//  Woke
//
//  Created by Lee on 9/25/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "PFObject+EWSync.h"
#import "EWSync.h"

@implementation PFObject(EWSync)
- (BOOL)updateFromManagedObject:(EWServerObject *)managedObject withError:(NSError *__autoreleasing *)error{

    [self fetchIfNeededAndSaveToCache:error];
    if (*error && self.objectId) {
        if ([*error code] == kPFErrorObjectNotFound) {
            DDLogError(@"PO %@(%@) not found on server!", self.parseClassName, self.objectId);
            NSManagedObject *trueMO = [managedObject.managedObjectContext existingObjectWithID:managedObject.objectID error:NULL];
            if (trueMO) {
                [managedObject setValue:nil forKeyPath:kParseObjectID];
            }
        }
        else{
            DDLogError(@"Trying to upload but PO error fetching: %@. Skip!", [*error localizedDescription]);
        }
        
        [managedObject uploadEventually];
        return NO;
    }
    
    //If PO just created, the PO is newer than MO, this is not reliable. Also, it is against the intention. Therefore, the intention of upload should overload the fact that PO is newer.
    //    if (self.isNewerThanMO) {
    //        NSLog(@"@@@ Trying to update MO %@, but PO is newer! Please check the code.(%@ -> %@)", managedObject.entity.name, [managedObject valueForKey:kUpdatedDateKey], self.updatedAt);
    //        return;
    //    }
    
    
    NSArray *changeValues = [[EWSync sharedInstance].changedRecords objectForKey:managedObject.serverID];
    [managedObject.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *obj, BOOL *stop) {
		BOOL expectChange = [changeValues containsObject:key] ? YES : NO;
		
        //check if need to skip
        if (key.skipUpload) {
            return;
        }
        
        //=============== ATTRIBUTES ===============
        id value = [managedObject valueForKey:key];
        id POValue = [self valueForKey:key];
        
        //there could have some optimization that checks if value equals to PFFile value, and thus save some network calls. But in order to compare there will be another network call to fetch, the the comparison is redundant.
        if ([value isKindOfClass:[NSData class]]) {
            //data
            if (!expectChange && POValue) {
                DDLogVerbose(@"MO attribute %@(%@)->%@ expect no change", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], key);
                return;
            }
            NSString *fileName = [NSString stringWithFormat:@"%@.m4a", [PFUser currentUser][@"name"]];
            PFFile *dataFile = [PFFile fileWithName:fileName data:value contentType:@"audio/mp4"];
            [self setObject:dataFile forKey:key];
        }
        else if ([value isKindOfClass:[UIImage class]]){
            //image
            if (!expectChange && POValue) {
                DDLogVerbose(@"MO attribute %@(%@)->%@ expect no change", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], key);
                return;
            }
            PFFile *dataFile = [PFFile fileWithName:@"image.png" data:UIImagePNGRepresentation((UIImage *)value) contentType:@"image/png"];
            [self setObject:dataFile forKey:key];
        }
        else if ([value isKindOfClass:[CLLocation class]]){
            //location
            PFGeoPoint *point = [PFGeoPoint geoPointWithLocation:(CLLocation *)value];
            [self setObject:point forKey:key];
        }
        else if(value){
            [self setObject:value forKey:key];
        }
        else{
            //value is nil, delete PO value
            if ([self.allKeys containsObject:key]) {
                DDLogWarn(@"~~~> Delete %@ on PO %@(%@) when updating from MO, please check!", key, managedObject.entity.name, managedObject.serverID);
                [self removeObjectForKey:key];
            }
        }
    }];
    
    //=============== relation ===============
    [managedObject.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relation, BOOL *stop) {
		BOOL expectChange = [changeValues containsObject:key] ? YES : NO;
        id relatedManagedObjects = [managedObject valueForKey:key];
        
        if ([relation isToMany]) {
            
            //To-Many relation
            //First detect if has inverse relation, if not, we use Array to represent the relation
            //THOUGHTS: if the relation is linked to a user, we still use PFRelation as the size of PFObject will be too large for Array to store PFUser
            if (!relation.inverseRelationship/* && ![key isEqualToString:kUserClass]*/) {
                //No inverse relation, use array of pointer
                
                NSSet *relatedMOs = [managedObject valueForKey:key];
                NSMutableArray *relatedPOs = [NSMutableArray new];
                for (EWServerObject *MO in relatedMOs) {
                    //PFObject *PO = [EWDataStore getCachedParseObjectForID:MO.serverID];
                    //if (!PO) {
                    PFObject *PO = [PFObject objectWithoutDataWithClassName:MO.serverClassName objectId:[MO valueForKey:kParseObjectID]];
                    //}
                    if (PO.objectId) {
                        [relatedPOs addObject:PO];
                    }else{
                        NSLog(@"objectId not found");
                    }
                }
                [self setObject:[relatedPOs copy] forKey:key];
                return;
            }
            
            //========================== relation ==========================
            PFRelation *parseRelation = [self relationForKey:key];
            if (parseRelation.targetClass) {
                NSAssert([parseRelation.targetClass isEqualToString:relation.destinationEntity.name.serverClass], @"PFRelation target class(%@) is not equal to that from  entity info(%@)", parseRelation.targetClass, relation.entity.name);
            }
            
            //THOUGHTS: create a new PFRelation so that we don't need to deal with deletion
            
            //Find related PO to delete async
            NSMutableArray *relatedParseObjects = [[[parseRelation query] findObjects] mutableCopy];
            if (relatedParseObjects.count) {
                NSArray *relatedParseObjectsToDelete = [relatedParseObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, [relatedManagedObjects valueForKey:kParseObjectID]]];
                for (PFObject *PO in relatedParseObjectsToDelete) {
                    [parseRelation removeObject:PO];
                    //We don't update the inverse PFRelation as they should be updated from that MO
                    DDLogVerbose(@"~~~> To-many relation on PO %@(%@)->%@(%@) deleted when updating from MO", managedObject.entity.name, managedObject.serverID, key, PO.objectId);
                    if (!expectChange) DDLogVerbose(@"Relation %@ doesn't expect to change!", key);
                }
            }
            
            //related managedObject that needs to add
            for (EWServerObject *relatedManagedObject in relatedManagedObjects) {
                NSString *parseID = relatedManagedObject.serverID;
                if (parseID) {
                    //the pfobject already exists, need to inspect PFRelation to determin add or remove
                    if (![[relatedParseObjects valueForKey:kParseObjectID] containsObject:parseID]) {
                        PFObject *relatedParseObject = [PFObject objectWithoutDataWithClassName:relatedManagedObject.serverClassName objectId:parseID];
                        
                        DDLogVerbose(@"+++> To-many relation on PO %@(%@)->%@(%@) added when updating from MO", managedObject.entity.name, managedObject.serverID, key, relatedParseObject.objectId);
                        if (!expectChange) DDLogVerbose(@"Relation %@ doesn't expect to change!", key);
                        [parseRelation addObject:relatedParseObject];
                    }
                }
                else {
                    __block PFObject *blockObject = self;
                    __block PFRelation *blockParseRelation = parseRelation;
                    if (!expectChange) DDLogVerbose(@"Relation %@ doesn't expect to change!", key);
                    //set up a saving block
                    //NSLog(@"Relation %@ -> %@ save block setup", blockObject.parseClassName, relatedManagedObject.entity.serverClassName);
                    PFObjectResultBlock connectRelationship = ^(PFObject *object, NSError *error) {
                        //the relation can only be additive, which is not a problem for new relation
                        [blockParseRelation addObject:object];
                        [blockObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *e   ) {
                            DDLogInfo(@"PO Relation %@(%@) -> %@ (%@) established in PO save callback", blockObject.parseClassName, blockObject.objectId, key, object.objectId);
                            if (e) {
                                DDLogError(@"Failed to save: %@", e.description);
                                @try {
                                    [blockObject saveEventually];
                                }
                                @catch (NSException *exception) {
                                    [managedObject uploadEventually];
                                    DDLogError(@"saveEventually failed, move to uploadEventually, got exeption:%@", exception);
                                }
                            }
                        }];
                    };
                    
                    //add to global save callback distionary
                    [[EWSync sharedInstance] addSaveCallback:connectRelationship forManagedObjectID:relatedManagedObject.objectID];
                    
                    //add relatedMO to insertQueue
                    if (![[EWSync sharedInstance] contains:relatedManagedObject inQueue:kParseQueueWorking]) {
                        DDLogWarn(@"Added missing insert object: %@", relatedManagedObject);
                        [[EWSync sharedInstance] appendInsertQueue:relatedManagedObject];
                    }
                }
            }
        }
        else {
            //TO-One relation
            if (relatedManagedObjects) {
                EWServerObject *relatedMO = (EWServerObject *)relatedManagedObjects;
                NSString *parseID = relatedMO.serverID;
                PFObject *relatedPO = self[key];
                if (parseID) {
                    if (![parseID isEqualToString:relatedPO.objectId]) {
                        relatedPO = [PFObject objectWithoutDataWithClassName:relatedMO.serverClassName objectId:parseID];
                        [self setObject:relatedPO forKey:key];
                        DDLogVerbose(@"+++> To-one relation on PO %@(%@)->%@(%@) added when updating from MO", managedObject.entity.name, [managedObject valueForKey:kParseObjectID], relation.name, relatedPO.objectId);
                        if (!expectChange) DDLogVerbose(@"Relation %@ doesn't expect to change!", key);
                    }
                }
                else {
                    //MO doesn't have parse id, save to parse
                    __block PFObject *blockObject = self;
                    if (!expectChange) DDLogVerbose(@"Relation %@ doesn't expect to change!", key);
                    //set up a saving block
                    PFObjectResultBlock connectRelationship = ^(PFObject *object, NSError *error2) {
                        [blockObject setObject:object forKey:key];
                        [blockObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error3) {
                            //relationship can be saved regardless of network condition.
                            if (error3) {
                                DDLogError(@"Failed to save: %@", error3.description);
                                @try {
                                    [blockObject saveEventually];
                                }
                                @catch (NSException *exception) {
                                    [managedObject uploadEventually];
                                }
                            }
                        }];
                    };
                    //add to global save callback distionary
                    [[EWSync sharedInstance] addSaveCallback:connectRelationship forManagedObjectID:relatedMO.objectID];
                    
                    //add relatedMO to insertQueue
                    if (![[EWSync sharedInstance] contains:relatedMO inQueue:kParseQueueWorking]) {
                        DDLogWarn(@"Added missing insert object: %@", relatedMO);
                        [[EWSync sharedInstance] appendInsertQueue:relatedMO];
                    }
                }
            }else{
                //delete
                DDLogVerbose(@"~~~>Empty relationship on MO %@(%@) -> %@, delete PO relation.", managedObject.entity.name, self.objectId, relation.name);
                [self removeObjectForKey:key];
            }
        }
    }];
    return YES;
}

- (EWServerObject *)managedObjectInContext:(NSManagedObjectContext *)context{
	return [self managedObjectInContext:context option:EWSyncOptionUpdateAttributesOnly completion:NULL];
}

- (EWServerObject *)managedObjectUpdatedInContext:(NSManagedObjectContext *)context{
	return [self managedObjectInContext:context option:EWSyncOptionUpdateRelation completion:NULL];
}

- (EWServerObject *)managedObjectInContext:(NSManagedObjectContext *)context option:(EWSyncOption)option completion:(void (^)(EWServerObject *, NSError *))block{
	if (!self.objectId) {
		return nil;
	}
	
	if (!context) {
		EWAssertMainThread
		context = mainContext;
	}
    
    NSError *error;
	[self fetchIfNeededAndSaveToCache:&error];
	
	NSMutableArray *MOs = [[NSClassFromString(self.localClassName) MR_findByAttribute:kParseObjectID withValue:self.objectId inContext:context] mutableCopy];
    if (MOs.count > 1) {
		DDLogError(@"Find %ld duplicated MO for ID %@(%@)", MOs.count, self.localClassName, self.objectId);
        for (EWServerObject *mo_ in MOs){
            if (![mo_ validate]) {
                [mo_ remove];
                //remove from the update queue
                [[EWSync sharedInstance] removeObjectFromDeleteQueue:self];
            }
        }
        while (MOs.count > 1) {
            EWServerObject *mo_ = MOs.firstObject;
            [mo_ remove];
            //remove from the update queue
            [[EWSync sharedInstance] removeObjectFromDeleteQueue:self];
        }
	}
	EWServerObject *MO = MOs.firstObject;
	
	if (!MO) {
		//if managedObject not exist, create it locally by assigning value from PO (quick)
		//and assign relation in child context
		MO = [NSClassFromString(self.localClassName) MR_createInContext:context];
        if (option == EWSyncOptionUpdateNone) {
            [MO assignValueFromParseObject:self];
        }else {
            MO.createdAt = self.updatedAt;
            MO.objectId = self.objectId;
        }
		
		DDLogInfo(@"+++> MO created: %@ (%@)", self.localClassName, self.objectId);
	}
    
    BOOL attrbutesNeedUpdate = [self needToUpdateMOAttributesInContext:context];
    BOOL relationNeedUpdate = [self isNewerThanMOInContext:context];
    BOOL isUserClass = [MO.entity.name isEqualToString:kSyncUserClass];
    //try to sync relation
    if (relationNeedUpdate) {
        if (option == EWSyncOptionUpdateRelation) {
            [MO updateValueAndRelationFromParseObject:self];
            if (block) {
                block(MO, error);
            }
            return MO;
        }
        else if (option == EWSyncOptionUpdateAsync){
            [MO assignValueFromParseObject:self];
            [context saveWithBlock:^(NSManagedObjectContext *localContext) {
                EWServerObject *localSO = [MO MR_inContext:localContext];
                [localSO updateValueAndRelationFromParseObject:self];
            } completion:^(BOOL contextDidSave, NSError *error) {
                if (block) {
                    block(MO, error);
                }
            }];
            return MO;
        }else if (!isUserClass) {
            DDLogInfo(@"PO %@(%@) is newer than MO, but MO relation not updated with sync option %lu!", self.parseClassName, self.objectId, option);
        }
    }
    //try to assign value only
    if (attrbutesNeedUpdate && option != EWSyncOptionUpdateNone) {
        [MO assignValueFromParseObject:self];
    }
    
    if (block) {
        block(MO, error);
    }
	return MO;
}

- (BOOL)isNewerThanMO{
    return [self isNewerThanMOInContext:mainContext];
}

- (BOOL)isNewerThanMOInContext:(NSManagedObjectContext *)context{
    NSDate *updatedPO = [self valueForKey:kUpdatedDateKey];
    EWServerObject *mo = (EWServerObject *)[NSClassFromString(self.localClassName) MR_findFirstByAttribute:kParseObjectID withValue:self.objectId inContext:context];
    NSDate *updatedMO = mo.updatedAt;
    if (updatedPO && updatedMO) {
        if ([updatedPO timeIntervalSinceDate:updatedMO]>1) {
            //DDLogVerbose(@"PO is newer than MO: %@ > %@", updatedPO, updatedMO);
            return YES;
        }else{
            return NO;
        }
    }else if (updatedMO){
        return NO;
    }else if (updatedPO){
        return YES;
    }
    return NO;
}

- (BOOL)needToUpdateMOAttributesInContext:(NSManagedObjectContext *)context {
    NSDate *updatedPO = self.updatedAt;
    EWServerObject *mo = (EWServerObject *)[NSClassFromString(self.localClassName) MR_findFirstByAttribute:kParseObjectID withValue:self.objectId inContext:context];
    NSDate *updatedMO = mo.syncInfo[kAttributeUpdatedTime];
    if (updatedPO && updatedMO) {
        if ([updatedPO timeIntervalSinceDate:updatedMO]>1) {
            return YES;
        }else{
            return NO;
        }
    }else if (updatedMO){
        return NO;
    }else if (updatedPO){
        return YES;
    }
    return NO;
}

- (NSString *)localClassName{
    NSDictionary *map = kServerTransformClasses;
    NSString *localClass = [[map allKeysForObject:self.parseClassName] firstObject];
    return localClass ?: self.parseClassName;
}

#pragma mark - Cache
- (void)fetchIfNeededAndSaveToCache:(NSError *__autoreleasing *)error{
	if (!error) {
		NSError *__autoreleasing err;
		error = &err;
	}
    if (!self.isDataAvailable) {
        [self fetch:error];
        if (*error) {
            if ([*error code] == kPFErrorObjectNotFound) {
                DDLogError(@"PO %@(%@) not found on server!", self.parseClassName, self.objectId);
                [self delete];
            }
            else{
                DDLogError(@"Trying to upload but PO error fetching: %@. Skip!", [*error localizedDescription]);
            }
            return;
        }
    }
    NSDate *updated = self.updatedAt;
    PFObject *cachedObject = [[EWSync sharedInstance] getCachedParseObjectForID:self.objectId];
    NSDate *cacheUpdated = cachedObject.updatedAt;
    float interval = [updated timeIntervalSinceDate:cacheUpdated];
    if (!cacheUpdated || interval > 0) {
        //self newer
        [[EWSync sharedInstance] setCachedParseObject:self];
        DDLogVerbose(@"Cached PO %@(%@)", self.parseClassName, self.objectId);
    }
    else if (interval < 0) {
        //cache newer
        DDLogWarn(@"Cache is newer than current PO: %@(%@)", self.parseClassName, self.objectId);
    }
}
@end
