//
//  NSManagedObject(Parse).h
//  Woke
//
//  Created by Lee on 9/25/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Parse/Parse.h>
#import "EWServerObject.h"

#define kAttributeUpdatedTime   @"attribute_update_time"
#define kRelationUpdatedTime    @"relation_update_time"

#define kServerTransformTypes       @{@"CLLocation": @"PFGeoPoint"} //localType: serverType
#define kServerTransformClasses     @{@"EWPerson": @"_User"} //localClass: serverClass

@interface EWServerObject(EWSync)
/**
 Update ManagedObject from correspoinding Server Object
 
 *1) First assign the attribute value from server object
 
 *2) Iterate through the relations
 **   -> Delete obsolete related object.
 **   -> For each end point in relationship, To-Many or To-One, find or create MO and assign value to that relationship.
 @discussion The attributes and relationship are updated in sync.
 */
- (void)updateValueAndRelationFromParseObject:(PFObject *)object;

/**
 Get conterparty Parse Object and refresh from server if needed
 */
//- (PFObject *)parseObject;

/**
 *  get server(parse) object in background
 *
 *  @param block returns a PFObject and a NSError
 */
//- (void)getParseObjectInBackgroundWithCompletion:(PFObjectResultBlock)block;

/**
 Refresh ManagedObject value from server in background
 @discussion If the ParseID is not found on this ManagedObject, an insert action will performed.
 */
- (void)refreshInBackgroundWithCompletion:(ErrorBlock)block;

/**
 Refresh ManagedObject value from server in the current thread
 @discussion If the ParseID is not found on this ManagedObject, an insert action will performed.
 */
- (BOOL)refresh:(NSError **)error;
- (BOOL)refreshInContext:(NSManagedObjectContext *)context withError:(NSError **)error;

/**
 *Refresh related MO from server in background.
 *
 *This method iterates all objects related to the MO and refresh (updatedDate) to make sure my relevant data is copied locally.
 *
 *It also checks that if any data on server has duplication.
 *@discussion it is usually used for current user object (me)
 */
//- (void)refreshRelatedWithCompletion:(ErrorBlock)block;

/**
 Update object from PO for value, and related PO that is returned as Array of pointers
 The goal is to call server once and get as much as possible.
 */
- (void)refreshShallowWithCompletion:(ErrorBlock)block;

/**
 Assign only attribute values (not relation) to the ManagedObject from the Parse Object
 */
- (void)assignValueFromParseObject:(PFObject *)object;

/**
 Save ManagedObjectID into update queue in userDefaults
 */
- (void)uploadEventually;

/**
 Save ManagedObjectID into delete queue in userDefaults
 */
- (void)deleteEventually;

#pragma mark - Sync Status

/**
 Changed keys beyond those excluded.
 */
- (NSArray *)changedKeys;

/**
 Check if the MO's updatedAt time is more than the server refresh interval
 */
- (BOOL)isOutDated;

/**
 Updated time:
 If need to update relation, return kRelationUpdatedTime
 If only need to update properties, return kAttributeUpdatedTime
 */
- (NSDate *)updatedTime;

/**
 *  The owner of this object, used to determine if we need to fully download the object or upload this object to server.
 *  @attention EWPerson will return itself
 *  @return Owner
 */
//- (EWServerObject *)ownerObject;

#pragma mark - Transaction
/**
 Mark MO as to save locally and remove MO from upload queue
 */
//- (void)saveToLocal;
/**
 Mark MO to upload to server and insert MO to upload queue
 */
//- (void)saveToServer;

/**
 *  Upload to server immediately
 *
 *  @param block Passing EWServerObject's counterparty - PFObject back to the block
 */
- (void)updateToServerWithCompletion:(EWManagedObjectSaveCallbackBlock)block;

#pragma mark - Helper methods
/**
 Reflex method to search for runtime attributes
 */
- (NSString *)getPropertyClassByName:(NSString *)name;



#pragma mark - server Translation
- (EWServerObject *)ownerObject;
+ (NSString *)serverClassName;
+ (NSString *)serverPropertyTypeForLocalType:(NSString *)localClass;
+ (NSArray *)propertiesSkippedToUpload;
+ (BOOL)fetchRelation;

@end

