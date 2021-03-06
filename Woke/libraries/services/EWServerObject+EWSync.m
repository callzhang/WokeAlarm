//
//  NSManagedObject(Parse).m
//  Woke
//
//  Created by Lee on 9/25/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWServerObject+EWSync.h"
#import "EWSync.h"
#import "EWPerson.h"
#import <objc/runtime.h>
#import "EWUtil.h"
#import "NSDictionary+KeyPathAccess.h"
#import "NSTimer+BlocksKit.h"
#import "EWErrorManager.h"

@implementation EWServerObject(EWSync)
#pragma mark - Server sync
//TODO: use advanced thread manageement to dispatch all background downloading task(updateValueAndRelationFromParseObject) to a single queue, so that the downloading tasks won't interfere each other and have unexpected result, such as duplicated object and missing property (due to deletion of duplications)
- (void)updateValueAndRelationFromParseObject:(PFObject *)parseObject{
    if (!parseObject) {
        DDLogError(@"%s PO is nil, please check!", __FUNCTION__);
        return;
    }
	if ([EWSync isUpdating:self]) {
		DDLogWarn(@"Found MO already refreshing %@(%@), skip!", self.entity.class, self.serverID);
        return;
    }else {
        [EWSync addToUpdatingMarks:self];
    }
    
    //download data: the fetch here is just a prevention or default state that data is only refreshed when absolutely necessary. If we need check new data, we should refresh PO before passed in here. For example, we fetch PO at app launch for current user update purpose.
	NSError *err;
	[parseObject fetchIfNeededAndSaveToCache:&err];
	if (!parseObject.isDataAvailable) {
		if (err.code == kPFErrorObjectNotFound) {
			DDLogError(@"*** The PO %@(%@) you passed in doesn't have any data. Deleted from server?", parseObject.parseClassName, parseObject.objectId);
			NSManagedObject *trueSelf = [self.managedObjectContext existingObjectWithID:self.objectID error:&err];
			if (trueSelf) {
				[self setValue:nil forKeyPath:kParseObjectID];
			}
		}
		return;
	}
	
    NSManagedObjectContext *localContext = self.managedObjectContext;
    
    
    //Assign attributes
    [self assignValueFromParseObject:parseObject];
    
    //realtion
    NSMutableDictionary *relations = [self.entity.relationshipsByName mutableCopy];
    [relations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relation, BOOL *stop) {
        
        if ([relation isToMany]) {
            //if no inverse relation, use Array of pointers
            if (!relation.inverseRelationship) {
                DDLogVerbose(@"Working on uni-directional relation %@->%@", self.entity.name, key);
                NSArray *relatedPOs = parseObject[key];
                NSMutableSet *relatedMOs = [NSMutableSet new];
                for (PFObject *PO in relatedPOs) {
                    if ([PO isKindOfClass:[NSNull class]]) continue;
                    [relatedMOs addObject: [PO managedObjectInContext:localContext]];
                }
                [self setValue:[relatedMOs copy] forKey:key];
                return ;
            }
            
            //Fetch PFRelation for normal relation
            PFRelation *toManyRelation = [parseObject relationForKey:key];
            if (!toManyRelation){
                [self setValue:nil forKey:key];
                return;
            }
            
            //============> download related PO <============
            NSError *err2;
            PFQuery *relationQueue = [toManyRelation query];
            [relationQueue fromLocalDatastore];
            NSArray *relatedParseObjects = [relationQueue findObjects:&err2];
            
            //handle error
            if ([err2 code] == kPFErrorObjectNotFound) {
                DDLogWarn(@"*** Uh oh, we couldn't find the related PO!");
                NSManagedObject *trueSelf = [self.managedObjectContext existingObjectWithID:self.objectID error:NULL];
                if (trueSelf) {
                    [self setValue:nil forKey:key];
                }
                return;
            } else if ([err2 code] == kPFErrorConnectionFailed) {
                DDLogWarn(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                [self uploadEventually];
            } else if (err2) {
                DDLogError(@"Error: %@", [err2 userInfo][@"error"]);
                return;
            }
            
            //found MO's relatedMOs that aren't on server to delete
            NSMutableSet *relatedManagedObjects = [self mutableSetValueForKey:key];
            NSSet *managedObjectToDelete = [relatedManagedObjects filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, [relatedParseObjects valueForKey:kParseObjectID]]];
            
            //substract deletedMOs from original relatedMOs
            [relatedManagedObjects minusSet:managedObjectToDelete];
            
            
            //Union original related MO and MOs referred from PO
            for (PFObject *object in relatedParseObjects) {
                //find corresponding MO
                NSManagedObject *relatedManagedObject = [object managedObjectInContext:localContext];
                [relatedManagedObjects addObject:relatedManagedObject];
            }
            [self setValue:relatedManagedObjects forKey:key];
            
            
        }else{
            //to one
            PFObject *relatedParseObject;
            @try {
                relatedParseObject = [parseObject valueForKey:key];
            }
            @catch (NSException *exception) {
                DDLogError(@"Failed to assign value of key: %@ from Parse Object %@ to ManagedObject %@ \n Error: %@", key, parseObject, self, exception.description);
                return;
            }
            if (relatedParseObject) {
                //find corresponding MO
                EWServerObject *relatedManagedObject = [relatedParseObject managedObjectInContext:localContext option:EWSyncOptionUpdateAttributesOnly completion:NULL];
                [self setValue:relatedManagedObject forKey:key];
            }else{
				//related PO is nil
				if ([self valueForKey:key]) {
					DDLogVerbose(@"~~~> Deleted to-one relation %@(%@)->%@(%@)", parseObject.parseClassName, parseObject.objectId, key, relatedParseObject.objectId);
					[self setValue:nil forKey:key];
				}
            }
        }
    }];
    
    //update updatedAtNSParameterAssert(self.syncInfo);
    self.syncInfo[kRelationUpdatedTime] = [NSDate date];
    //[self saveToLocal];
	
	//remove from updating MO
	[EWSync removeMOFromUpdating:self];
}



- (void)assignValueFromParseObject:(PFObject *)object{
    NSError *err;
    [object fetchIfNeededAndSaveToCache:&err];
    if (!object.isDataAvailable) {
        if (err.code == kPFErrorObjectNotFound) {
			DDLogError(@"*** The PO %@(%@) you passed in doesn't have any data. Deleted from server?", object.parseClassName, object.objectId);
            NSManagedObject *trueSelf = [self.managedObjectContext existingObjectWithID:self.objectID error:&err];
            if (trueSelf) {
                [self setValue:nil forKeyPath:kParseObjectID];
            }
        }
        return;
    }
    if (self.serverID) {
        NSParameterAssert([[self valueForKey:kParseObjectID] isEqualToString:object.objectId]);
    }else{
        self.objectId = object.objectId;
        self.createdAt = object.createdAt;
    }
    //attributes
    NSDictionary *managedObjectAttributes = self.entity.attributesByName;
    //add or delete some attributes here
    [managedObjectAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *obj, BOOL *stop) {
        id parseValue = [object valueForKey:key];
        
        //special treatment for PFFile
        if ([parseValue isKindOfClass:[PFFile class]]) {
            //update only it is outdated
            BOOL hasData = [self valueForKey:key] != nil;
            NSDate *time = self.syncInfo[key];
            BOOL upToDate = time && [time timeElapsed] < kServerUpdateInterval;
            if (hasData && upToDate) {
                DDLogVerbose(@"Skip downloading PFFile for %@(%@)->%@, last updated on %@", object.parseClassName, object.objectId, key, time);
                return;
            }
            //no data => sync
            //hasData => async
            //outDated => async
            
            //PFFile
            PFFile *file = (PFFile *)parseValue;
            NSString *className = [self getPropertyClassByName:key];
            if (hasData) { //download in background
                [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if (!data) {
                        [self refreshEventually];
                        DDLogError(@"Failed to download PFFile: %@", error.description);
                        return;
                    }
                    if ([className isEqualToString:@"UIImage"]) {
                        UIImage *img = [UIImage imageWithData:data];
                        [self setPrimitiveValue:img forKey:key];
                    }else{
                        [self setPrimitiveValue:data forKey:key];
                    }
                    //update sync info
                    self.syncInfo[key] = [NSDate date];
                }];
            }
            else{//download directly if no data
                NSError *error;
                NSData *data = [file getData:&error];
                if (!data) {
                    DDLogError(@"Failed to download PFFile: %@", error.description);
                    [self refreshEventually];
                    return;
                }
                if ([className isEqualToString:@"UIImage"]) {
                    UIImage *img = [UIImage imageWithData:data];
                    [self setPrimitiveValue:img forKey:key];
                }else{
                    [self setPrimitiveValue:data forKey:key];
                }
                //update sync info
                self.syncInfo[key] = [NSDate date];
            }
            
        }else if(parseValue && ![parseValue isKindOfClass:[NSNull class]]){
            //contains value
			NSString *localClass = [self getPropertyClassByName:key];
            NSString *serverClass = [[self class] serverPropertyTypeForLocalType:localClass];
            if (serverClass){
                
                //need to deal with local type
                if ([parseValue isKindOfClass:[PFGeoPoint class]]) {
                    PFGeoPoint *point = (PFGeoPoint *)parseValue;
                    CLLocation *loc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
                    [self setValue:loc forKey:key];
                }else{
                    [NSException raise:[NSString stringWithFormat:@"Server class %@ not handled (%@)", serverClass, key] format:@"Check your code!"];
                }
            }else{
                @try {
                    [self setPrimitiveValue:parseValue forKey:key];
                }
                @catch (NSException *exception) {
                    DDLogError(@"Failed to set value for key %@ on MO %@(%@)", key, self.entity.name, self.serverID);
                }
            }
        }else{
            //skip upload property will not be in the PO
            if ([[[self class] propertiesSkippedToUpload] containsObject:key]) return;
            //parse value empty, delete
			id MOValue = [self valueForKey:key];
            if (MOValue) {
                DDLogInfo(@"~~~> Delete attribute on MO %@(%@)->%@(%@)", self.entity.name, self.serverID, key, MOValue);
                [self setValue:nil forKey:key];
            }
        }
    }];
    //assigned value from PO should not be considered complete, therefore we don't timestamp updatedAt on this SO
    NSParameterAssert(self.syncInfo);
    self.syncInfo[kAttributeUpdatedTime] = [NSDate date];
    self.updatedAt = [NSDate date];
}

#pragma mark - Parse related
- (PFObject *)parseObject{
    
    NSError *err;
    PFObject *object = [[EWSync sharedInstance] getParseObjectWithClass:[[self class] serverClassName] ID:self.serverID error:&err];
    if (!object){
        DDLogError(@"Failed to find PO for MO %@(%@) with error: %@", self.entity.name, self.serverID, err.description);
        return nil;
    }
    
    //update value
    if ([object isNewerThanMOInContext:self.managedObjectContext]) {

        //if MO is dirty, we can't simply assign values to it
        if (!self.hasChanges) {
            [self assignValueFromParseObject:object];
        }else {
            DDLogWarn(@"%s PO(%@) newer than SO %@(%@)", __func__, object.objectId, self.entity.name, self.serverID);
        }
    }
    return object;
}

- (void)getParseObjectInBackgroundWithCompletion:(PFObjectResultBlock)block{
    EWAssertMainThread
    __block PFObject *object;
    __block NSError *err;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWServerObject *localMO = (EWServerObject *)[self MR_inContext:localContext];
        
        object = [[EWSync sharedInstance] getParseObjectWithClass:[[localMO class] serverClassName] ID:localMO.serverID error:&err];
        //update value
        if ([object isNewerThanMOInContext:localContext]) {
            DDLogWarn(@"Getting PO(%@) newer than SO %@(%@)", object.objectId, localMO.entity.name, localMO.serverID);
            [localMO updateValueAndRelationFromParseObject:object];
        }
    } completion:^(BOOL contextDidSave, NSError *error) {
        if (block) {
            block(object, err);
        }
    }];
}

#pragma mark - Download methods


- (void)refreshInBackgroundWithCompletion:(ErrorBlock)block{
    //network check
    EWAssertMainThread
    __block NSError *err;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        EWServerObject *currentMO = [self MR_inContext:localContext];
        if (!currentMO) {
            DDLogError(@"*** Failed to obtain object from database: %@", self);
            if (block) {
                block(nil);
            }
            return;
        }
        [self refreshInContext:localContext withError:&err];
    } completion:^(BOOL success, NSError *error) {
        if (block) {
            block(error?:err);
        }
        
    }];
}

- (BOOL)refresh:(NSError *__autoreleasing *)error{
	EWAssertMainThread
    __block BOOL success = NO;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        success = [self refreshInContext:localContext withError:error];
    }];
    return success;
}

- (BOOL)refreshInContext:(NSManagedObjectContext *)context withError:(NSError *__autoreleasing *)error{
    if (!error) {
        NSError __autoreleasing *err;
        error = &err;
    }
    //check network
    if (![EWSync isReachable]) {
        DDLogDebug(@"Network not reachable, refresh later.");
        //refresh later
        [self refreshEventually];
		*error = [EWErrorManager noInternetConnectError];
        return NO;
    }
    
    if (!self.serverID) {
        //[self uploadEventually];//potential to create a duplicate if MO is being downloaded
        DDLogWarn(@"!!! The MO %@(%@) trying to refresh doesn't have servreID, skip! %@", self.entity.name, self.serverID, self);
		*error = [EWErrorManager noServerIDError];
		[self uploadEventually];
		return NO;

    }else{
        NSParameterAssert(!self.hasChanges);
        
        DDLogVerbose(@"===>>>> Refreshing MO %@(%@)", self.entity.name, self.serverID);
        
        //get the PO
        PFObject *object = self.parseObject;
        //Must update the PO
        [object fetch:error];
        //update MO
        [self updateValueAndRelationFromParseObject:object];
        //save: already saved in update
        //[self saveToLocal];
    }
	
	return YES;
}

- (void)refreshEventually{
    [[EWSync sharedInstance] appendToDownloadQueue:self];
}

- (void)refreshRelatedWithCompletion:(ErrorBlock)block{
    if (![EWSync isReachable]) {
        DDLogWarn(@"Network not reachable, refresh later.");
        //refresh later
        if (block) {
            NSError *err = [[NSError alloc] initWithDomain:@"com.WokeAlarm" code:kEWSyncErrorNoConnection userInfo:@{NSLocalizedDescriptionKey: @"Server not reachable"}];
            block(err);
        }
        [self refreshEventually];
        return;
    }
    
    if (![self isKindOfClass:[EWPerson class]]) {
        if (block) {
            block(nil);
        }
        return;
    }
    
    //first try to refresh if needed
	[self refresh:nil];
	
    //then iterate all relations
    NSDictionary *relations = self.entity.relationshipsByName;
    [relations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *description, BOOL *stop) {
        if ([description isToMany]) {
            NSSet *relatedMOs = [self valueForKey:key];
            
            for (EWServerObject *MO in relatedMOs) {
                if ([MO isKindOfClass:[EWPerson class]]) {
                    return ;
                }
				[MO refresh:nil];
            }
        }else{
            EWServerObject *MO = [self valueForKey:key];
			[MO refresh:nil];
        }
    }];
    
    if (block) {
        block(nil);
    }
}

- (void)refreshShallowWithCompletion:(ErrorBlock)block{
    if (![EWSync isReachable]) {
        DDLogInfo(@"Network not reachable, refresh later.");
        //refresh later
        [self refreshEventually];
        if (block) {
            NSError *err = [[NSError alloc] initWithDomain:@"com.WokeAlarm" code:kEWSyncErrorNoConnection userInfo:@{NSLocalizedDescriptionKey: @"Server not reachable"}];
            block(err);
        }
        return;
    }
    
    if (!self.isOutDated) {
        if (block) {
            block(nil);
        }
        return;
    }
    
    NSManagedObjectID *ID = self.objectID;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSError *err;
        NSManagedObject *backMO = [localContext existingObjectWithID:ID error:&err];
        if (err) {
            DDLogError(@"*** Failed to get back MO: %@", err.description);
            return ;
        }
        
        //Get PO, also add inlcude key for pointer
        PFObject *PO = self.parseObject;
		[PO fetch:&err];
        
        //update properties
        [self assignValueFromParseObject:PO];
        
        //get related object parsimoniously, if it is in array form
        [backMO.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
            if (obj.isToMany) {
                if (!obj.inverseRelationship) {
                    //Pointer
                    NSArray *relatedPOs = PO[key];
                    if (relatedPOs.count == 0) {
                        return;
                    }
                    NSMutableSet *relatedMOs = [backMO mutableSetValueForKey:key];
                    for (PFObject *p in relatedPOs) {
                        if ([p isKindOfClass:[NSNull class]]) {
                            [relatedMOs removeObject:p];
                            PO[key] = relatedPOs;
                            if ([PO isEqual:[PFUser currentUser]]) {
                                [PO saveInBackground];
                            }
                            continue ;
                        }
                        NSManagedObject *relatedMO = [p managedObjectInContext:localContext];
                        if (![relatedMOs containsObject:relatedMO]) {
                            [relatedMOs addObject:relatedMO];
                        }
                    }
                    [backMO setValue:relatedMOs forKey:key];
                }
            }
        }];
        
        DDLogInfo(@"Shallow refreshed MO %@(%@) in backgound", PO.parseClassName, PO.objectId);
        
    }completion:^(BOOL success, NSError *error) {
        if (block) {
            block(error);
        }
        
        
    }];
    
}

- (void)uploadEventually{
    if (self.serverID) {
        //update
        DDLogInfo(@"%s: updated %@ eventually", __func__, self.entity.name);
        [[EWSync sharedInstance] appendUpdateQueue:self];
    }
    else{
        //insert
        DDLogInfo(@"%s: insert %@ eventually", __func__, self.entity.name);
        [[EWSync sharedInstance] appendInsertQueue:self];
    }
}

- (void)deleteEventually{
    PFObject *po = [PFObject objectWithoutDataWithClassName:self.entity.name objectId:self.serverID];
    DDLogInfo(@"%s: delete %@ eventually", __func__, self.entity.name);
    [[EWSync sharedInstance] appendObjectToDeleteQueue:po];
    
    //delete
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext deleteObject:self];
    }];
}

#pragma mark - Status
- (NSArray *)changedKeys{
    NSMutableArray *changes = self.changedValues.allKeys.mutableCopy;
    [changes removeObjectsInArray: [[self class] propertiesSkippedToUpload]];
    if (changes.count > 0) {
        return changes;
    }
    return nil;
}

- (BOOL)isOutDated{
    NSDate *date = self.updatedTime;
    BOOL outdated = !(date.timeElapsed < kServerUpdateInterval);
    return outdated;
}

- (NSDate *)updatedTime{
    NSDate *date;
    if ([[self class] fetchRelation]) {
        date = self.syncInfo[kRelationUpdatedTime];
    } else {
        date = self.syncInfo[kAttributeUpdatedTime];
    }
    return date;
}

#pragma mark - Network

//- (void)saveToLocal{
//	if (self.changedKeys.count == 0) {
//		return;
//	}
//    DDLogVerbose(@"MO %@(%@) save to local with changes %@", self.entity.name, self.serverID, self.changedKeys.string);
//    //mark MO as save to local
//    if (self.objectID.isTemporaryID) {
//        [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:NULL];
//    }
//    [[EWSync sharedInstance].saveToLocalItems addObject:self.objectID];
//    
//    //remove from queue
//    [[EWSync sharedInstance] removeObjectFromInsertQueue:self];
//    [[EWSync sharedInstance] removeObjectFromUpdateQueue:self];
//	
//	//save
//	if ([NSThread isMainThread]) {
//		[self save];
//    }
////    else if([EWSync checkAccess:self]){
////        self.updatedAt = [NSDate date];
////    }
//}
//
//- (void)saveToServer{
//    if (self.objectID.isTemporaryID) {
//        [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:NULL];
//    }
//    [[EWSync sharedInstance].saveToLocalItems removeObject:self.objectID];
//    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:NULL];
//    //[[EWSync sharedInstance] appendUpdateQueue:self];
//}


- (void)updateToServerWithCompletion:(EWManagedObjectSaveCallbackBlock)block{
//	if (!self.hasChanges) {
//        if (!self.serverID) {
//            //add to upload queue
//            [[EWSync sharedInstance] appendInsertQueue:self];
//        } else {
//            DDLogWarn(@"MO %@(%@) passed in for update has no changes", self.entity.name, self.serverID);
//            if (block) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    EWServerObject *MO_main = [self MR_inContext:mainContext];
//                    block(MO_main, nil);
//                });
//            }
//            return;
//        }
//	}
	
	//save and persistant ID
	[self save];
	
	//add to completion block
    [EWSync addUploadingCompletionBlocks:block forServerObject:self];
    
	//trigger save immediately
    [EWSync saveImmediately];
}

#pragma mark - Server translation
+ (NSString *)serverClassName{
    return NSStringFromClass(self);
}

+ (NSArray *)propertiesSkippedToUpload{
    return @[kParseObjectID, kUpdatedDateKey, kCreatedDateKey, @"syncInfo", @"ACL"];
}

+ (NSString *)serverPropertyTypeForLocalType:(NSString *)localClass{
    NSDictionary *typeDic = kServerTransformTypes;
    NSString *serverType = typeDic[localClass];
    return serverType;
}

//owner and relation
- (EWServerObject *)ownerObject{
    return nil;
}

+ (BOOL)fetchRelation{
    return YES;
}

#pragma mark - Inspector methods
- (NSString *)getPropertyClassByName:(NSString *)name{
    objc_property_t property = class_getProperty([self class], [name UTF8String]);
    const char * type = property_getAttributes(property);
    NSString * typeString = [NSString stringWithUTF8String:type];
    NSArray * attributes = [typeString componentsSeparatedByString:@","];
    NSString * typeAttribute = [attributes objectAtIndex:0];
    if ([typeAttribute hasPrefix:@"T@"]) {
        NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];  //turns @"NSDate" into NSDate
        return typeClassName;
    }
    return @"";
}

@end
