//
//  NSManagedObject(Parse).m
//  Woke
//
//  Created by Lee on 9/25/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "NSManagedObject+EWSync.h"
#import "EWSync.h"
#import "EWPerson.h"
#import <objc/runtime.h>

@implementation NSManagedObject(EWSync)
#pragma mark - Server sync
- (void)updateValueAndRelationFromParseObject:(PFObject *)parseObject{
    if (!parseObject) {
        DDLogError(@"%s PO is nil, please check!", __FUNCTION__);
        return;
    }
    if (!parseObject.isDataAvailable) {
        DDLogError(@"*** The PO %@(%@) you passed in doesn't have any data. Deleted from server?", parseObject.parseClassName, parseObject.objectId);
        return;
    }
    
    NSManagedObjectContext *localContext = self.managedObjectContext;
    
    //download data: the fetch here is just a prevention or default state that data is only refreshed when absolutely necessary. If we need check new data, we should refresh PO before passed in here. For example, we fetch PO at app launch for current user update purpose.
    [parseObject fetchIfNeeded];
    
    //Assign attributes
    [self assignValueFromParseObject:parseObject];
    
    //realtion
    NSMutableDictionary *relations = [self.entity.relationshipsByName mutableCopy];
    [relations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relation, BOOL *stop) {
        
        if ([relation isToMany]) {
            //if no inverse relation, use Array of pointers
            if (!relation.inverseRelationship) {
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
            
            //download related PO
            NSError *err;
            NSArray *relatedParseObjects = [[toManyRelation query] findObjects:&err];
            //TODO: handle error
            if ([err code] == kPFErrorObjectNotFound) {
                DDLogWarn(@"*** Uh oh, we couldn't find the related PO!");
                NSManagedObject *trueSelf = [self.managedObjectContext existingObjectWithID:self.objectID error:NULL];
                if (trueSelf) {
                    [self setValue:nil forKey:key];
                }
                return;
            } else if ([err code] == kPFErrorConnectionFailed) {
                DDLogWarn(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                [self uploadEventually];
            } else if (err) {
                DDLogError(@"Error: %@", [err userInfo][@"error"]);
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
                NSManagedObject *relatedManagedObject = [relatedParseObject managedObjectInContext:localContext];
                [self setValue:relatedManagedObject forKey:key];
            }else{
                //Handle no related PO, I doubt that we need to check the inverse related PO
                BOOL inverseRelationExists;
                NSManagedObject *relatedMO;
                PFObject *relatedPO;//related PO get from relatedMO
                
                if (!relation.inverseRelationship) {
                    //no inverse relation, skip check
                    [self setValue:nil forKey:key];
                    return;
                }else{
                    //relation empty, check inverse relation first
                    relatedMO = [self valueForKey:key];
                    if (!relatedMO) return;//no need to do anything
                    relatedPO = relatedMO.parseObject;//find relatedPO
                    //check if relatedPO's inverse relation contains PO
                    if (relation.inverseRelationship.isToMany) {
                        PFRelation *reflectRelation = [relatedPO valueForKey:relation.inverseRelationship.name];
                        NSArray *reflectPOs = [[reflectRelation query] findObjects];
                        inverseRelationExists = [reflectPOs containsObject:parseObject];
                    }else{
                        PFObject *reflectPO = [relatedPO valueForKey:relation.inverseRelationship.name];
                        inverseRelationExists = [reflectPO.objectId isEqualToString:parseObject.objectId];
                        //it could be that the inversePO is not our PO, in this case, the relation at server side is wrong, but we don't care?
                    }
                }
                
                if (!inverseRelationExists) {
                    //both side of PO doesn't have
                    [self setValue:nil forKey:key];
                    DDLogInfo(@"~~~> Delete to-one relation on MO %@(%@)->%@(%@)", self.entity.name, parseObject.objectId, relation.name, [relatedMO valueForKey:kParseObjectID]);
                }else{
                    DDLogError(@"*** Something wrong, the inverse relation %@(%@) <-> %@(%@) deoesn't agree", self.entity.name, [self valueForKey:kParseObjectID], relatedMO.entity.name, [relatedMO valueForKey:kParseObjectID]);
                    if (relatedPO.isNewerThanMO) {
                        //PO wins
                        [self setValue:nil forKey:key];
                    }
                }
            }
        }
    }];
    
    //update updatedAt
    [self setValue:[NSDate date] forKey:kUpdatedDateKey];
    
    //save to local has been applied in assignValueFromParseObject:
    if (self.hasChanges && ![[EWSync sharedInstance].saveToLocalItems containsObject:self.objectID]) {
        [self saveToLocal];
    }
    
}



- (void)assignValueFromParseObject:(PFObject *)object{
    NSError *err;
    [object fetchIfNeeded:&err];
    if (!object.isDataAvailable) {
        DDLogWarn(@"*** The PO %@(%@) you passed in doesn't have any data. Deleted from server?", object.parseClassName, object.objectId);
        if (err.code == kPFErrorObjectNotFound) {
            NSManagedObject *trueSelf = [self.managedObjectContext existingObjectWithID:self.objectID error:NULL];
            if (trueSelf) {
                [self setValue:nil forKeyPath:kParseObjectID];
            }
        }
        return;
    }
    if (self.serverID) {
        NSParameterAssert([[self valueForKey:kParseObjectID] isEqualToString:object.objectId]);
    }else{
        [self setValue:object.objectId forKey:kParseObjectID];
    }
    //attributes
    NSDictionary *managedObjectAttributes = self.entity.attributesByName;
    //NSArray *allKeys = object.allKeys;
    //add or delete some attributes here
    [managedObjectAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *obj, BOOL *stop) {
        key = [NSString stringWithFormat:@"%@", key];
        if (key.skipUpload) {
            //skip the updatedAt
            return;
        }
        id parseValue = [object objectForKey:key];
        //special treatment for PFFile
        if ([parseValue isKindOfClass:[PFFile class]]) {
            //PFFile
            PFFile *file = (PFFile *)parseValue;
            NSString *className = [self getPropertyClassByName:key];
            if ([NSThread isMainThread]) { //download in background
                [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if (!data) {
                        DDLogError(@"Failed to download PFFile: %@", error.description);
                        return;
                    }
                    if ([className isEqualToString:@"UIImage"]) {
                        UIImage *img = [UIImage imageWithData:data];
                        [self setValue:img forKey:key];
                    }else{
                        [self setValue:data forKey:key];
                    }
                }];
            }
            else{//download directly if already in background
                NSError *error;
                NSData *data = [file getData:&error];
                //[file getDataWithBlock:^(NSData *data, NSError *error) {
                if (!data) {
                    DDLogError(@"Failed to download PFFile: %@", error.description);
                    return;
                }
                if ([className isEqualToString:@"UIImage"]) {
                    UIImage *img = [UIImage imageWithData:data];
                    [self setValue:img forKey:key];
                }else{
                    [self setValue:data forKey:key];
                }
            }
            
        }else if(parseValue && ![parseValue isKindOfClass:[NSNull class]]){
            //contains value
            if ([[self getPropertyClassByName:key] serverType]){
                
                //need to deal with local type
                if ([parseValue isKindOfClass:[PFGeoPoint class]]) {
                    PFGeoPoint *point = (PFGeoPoint *)parseValue;
                    CLLocation *loc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
                    [self setValue:loc forKey:key];
                }else{
                    [NSException raise:@"Server class not handled" format:@"Check your code!"];
                }
            }else{
                @try {
                    [self setValue:parseValue forKey:key];
                }
                @catch (NSException *exception) {
                    DDLogError(@"Failed to set value for key %@ on MO %@(%@)", key, self.entity.name, self.serverID);
                }
            }
        }else{
            //parse value empty, delete
            if ([self valueForKey:key]) {
                //NSLog(@"~~~> Delete attribute on MO %@(%@)->%@", self.entity.name, [obj valueForKey:kParseObjectID], obj.name);
                [self setValue:nil forKey:key];
            }
        }
    }];
    //assigned value from PO should not be considered complete, therefore we don't timestamp on this SO
    //[self setValue:[NSDate date] forKey:kUpdatedDateKey];
    if (self.hasChanges) {
        //add save to local label
        [self saveToLocal];
    }
}

#pragma mark - Parse related
- (PFObject *)parseObject{
    
    NSError *err;
    PFObject *object = [[EWSync sharedInstance] getParseObjectWithClass:self.serverClassName ID:self.serverID error:&err];
    if (err){
        DDLogError(@"Failed to find PO for MO(%@) with error: %@", self.serverID, err.description);
        return nil;
    }
    
    //update value
    if ([object isNewerThanMO]) {
        [self assignValueFromParseObject:object];
    }
    return object;
}


#pragma mark - Download methods


- (void)refreshInBackgroundWithCompletion:(ErrorBlock)block{
    //network check
    if (![EWSync isReachable]) {
        DDLogDebug(@"Network not reachable, skip refreshing.");
        //refresh later
        [self refreshEventually];
        if (block) {
            NSError *err = [[NSError alloc] initWithDomain:@"com.WokeAlarm" code:kEWSyncErrorNoConnection userInfo:@{NSLocalizedDescriptionKey: @"Server not reachable"}];
            block(err);
        }
        return;
    }
    
    if (!self.serverID) {
        DDLogVerbose(@"When refreshing, MO missing serverID %@, prepare to upload", self.entity.name);
        [self uploadEventually];
        [EWSync save];
        NSError *err = [[NSError alloc] initWithDomain:@"com.WokeAlarm" code:kEWSyncErrorNoServerID userInfo:@{NSLocalizedDescriptionKey: @"No object identification (objectId) available"}];
        if (block) {
            block(err);
        }
    }else{
        [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSManagedObject *currentMO = [self MR_inContext:localContext];
            if (!currentMO) {
                DDLogError(@"*** Failed to obtain object from database: %@", self);
                if (block) {
                    block(nil);
                }
                return;
            }
            //============ Refresh
            [currentMO refresh];
            //=====================
            
        } completion:^(BOOL success, NSError *error) {
            if (block) {
                block(error);
            }
            
        }];
        
        
    }
}

- (void)refresh{
    //check network
    if (![EWSync isReachable]) {
        DDLogDebug(@"Network not reachable, refresh later.");
        //refresh later
        [self refreshEventually];
        return;
    }
    
    if (!self.serverID) {
        //NSParameterAssert([self isInserted]);
        DDLogWarn(@"!!! The MO %@(%@) trying to refresh doesn't have servreID, skip! %@", self.entity.name, self.serverID, self);
    }else{
        if ([self changedKeys]) {
            DDLogVerbose(@"The MO%@ (%@) you are trying to refresh HAS CHANGES, which makes the process UNSAFE!(%@)", self.entity.name, self.serverID, self.changedKeys);
        }
        
        DDLogInfo(@"===>>>> Refreshing MO %@(%@)", self.entity.name, self.serverID);
        //get the PO
        PFObject *object = self.parseObject;
        //Must update the PO
        [object fetch];
        //update MO
        [self updateValueAndRelationFromParseObject:object];
        //save: already saved in update
        //[self saveToLocal];
    }
}

- (void)refreshEventually{
    [[EWSync sharedInstance] appendObject:self toQueue:kParseQueueRefresh];
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
    [self refresh];
    
    //then iterate all relations
    NSDictionary *relations = self.entity.relationshipsByName;
    [relations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *description, BOOL *stop) {
        if ([description isToMany]) {
            NSSet *relatedMOs = [self valueForKey:key];
            
            for (NSManagedObject *MO in relatedMOs) {
                if ([MO isKindOfClass:[EWPerson class]]) {
                    return ;
                }
                [MO refresh];
            }
        }else{
            NSManagedObject *MO = [self valueForKey:key];
            [MO refresh];
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
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSError *err;
        NSManagedObject *backMO = [localContext existingObjectWithID:ID error:&err];
        if (err) {
            DDLogError(@"*** Failed to get back MO: %@", err.description);
            return ;
        }
        
        //Get PO from server, also add inlcude key for pointer
        PFObject *PO = self.parseObject;
        
        //update properties
        [self assignValueFromParseObject:PO];
        
        //get related object parsimoniously, if
        [backMO.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
            if (obj.isToMany) {
                if (obj.inverseRelationship) {
                    //PFRelation, skip
                }else{
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

#pragma mark - Tools

- (NSArray *)changedKeys{
    NSMutableArray *changes = self.changedValues.allKeys.mutableCopy;
    [changes removeObjectsInArray:attributeUploadSkipped];
    if (changes.count > 0) {
        return changes;
    }
    return nil;
}

- (void)saveToLocal{
    //mark MO as save to local
    if (self.objectID.isTemporaryID) {
        [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:NULL];
    }
    [[EWSync sharedInstance].saveToLocalItems addObject:self.objectID];
    
    //remove from queue
    [[EWSync sharedInstance] removeObjectFromInsertQueue:self];
    [[EWSync sharedInstance] removeObjectFromUpdateQueue:self];
}

- (void)saveToServer{
    if (self.objectID.isTemporaryID) {
        [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:NULL];
    }
    [[EWSync sharedInstance].saveToLocalItems removeObject:self.objectID];
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:NULL];
    //[[EWSync sharedInstance] appendUpdateQueue:self];
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

- (BOOL)isOutDated{
    NSDate *date = (NSDate *)[self valueForKey:kUpdatedDateKey];
    if (!date) {
        return YES;
    }
    BOOL outdated = !date.isUpToDated;
    return outdated;
}

- (NSString *)serverID{
    return [self valueForKey:kParseObjectID];
}

- (NSString *)serverClassName{
    NSDictionary *map = kServerTransformClasses;
    NSString *serverClass = [map objectForKey:self.entity.name];
    return serverClass ?: self.entity.name;
}


@end
