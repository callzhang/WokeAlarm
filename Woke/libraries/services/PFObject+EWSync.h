//
//  PFObject+EWSync.h
//  Woke
//
//  Created by Lee on 9/25/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <Parse/Parse.h>

typedef enum : NSUInteger {
	EWSyncOptionUpdateRelation = 1,
	EWSyncOptionUpdateAttributesOnly = 1<< 2,
	EWSyncOptionUpdateNone = 1 << 3,
	EWSyncOptionUpdateAsync = 1 << 4,
    EWSyncOptionAutomatic = 1 << 5
} EWSyncOption;

@class EWServerObject;
@interface PFObject(EWSync)
/**
 Update parse value and relation to server object. Create if no ParseID on ManagedObject.
 1) First assign the attribute value from ManagedObject
 2) Iterate through the relations described by entityDescription
 -> Delete obsolete related object async
 -> For each end point in relationship, To-Many or To-One, find corresponding PO and assign value to that relationship. If parseID not exist on that MO, it creates a save callback block, indicating that there is a 'need' to establish relation to that PO once it is created on server.
 @discussion The attributes are updated in sync, the relationship is updated async for new andn deleted related objects.
 */
- (BOOL)updateFromManagedObject:(NSManagedObject *)managedObject withError:(NSError **)error;

/**
 The ManagedObject will only update attributes but not relations
 */
- (EWServerObject *)managedObjectInContext:(NSManagedObjectContext *)context;
//- (EWServerObject *)managedObjectRelationUpdatedInContext:(NSManagedObjectContext *)context;
- (EWServerObject *)managedObjectInContext:(NSManagedObjectContext *)context option:(EWSyncOption)option completion:(void (^)(EWServerObject *SO, NSError *error))block;

//Helper
- (BOOL)isNewerThanMO;
- (BOOL)isNewerThanMOInContext:(NSManagedObjectContext *)context;
- (NSString *)localClassName;

//cache
- (BOOL)fetchIfNeededAndSaveToCache:(NSError **)error;
@end