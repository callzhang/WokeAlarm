//
//  EWSync.h
//  Woke
//
//  Created by Lee on 9/24/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Parse/Parse.h>
#import "EWServerObject+EWSync.h"
#import "PFObject+EWSync.h"
#import "EWServerObject.h"

extern NSManagedObjectContext *mainContext;
typedef void (^EWManagedObjectSaveCallbackBlock)(EWServerObject *MO_on_main_thread, NSError *error);


//Diagram:
//https://drive.draw.io/#G0B8EqrGjPaSeTakN6VzRwZzdFaDA

//Error codes:
//http://parse.com/docs/dotnet/api/html/T_Parse_ParseException_ErrorCode.htm
//or https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/index.html#//apple_ref/doc/constant_group/NSError_Codes
#define kEWSyncErrorNoConnection            668 //NO_CONNECTION
#define kEWSyncErrorNoServerID              113 //NO_MORE_SEARCH_HANDLES: No more internal file identifiers available
#define kEWSyncErrorNoPermission            257;

#pragma mark - Sync parameters
#define kSyncUserClass                      @"EWPerson"
#define kUserID                             @"userId"
#define kUsername                           @"username"

//Server update time
#define kStalelessInterval                  30
#define kUploadLag                          10
#define kCacheLifeTime                      60*60 //1hr

//attribute stored on ManagedObject to identify corresponding PFObject on server
#define kParseObjectID                      @"objectId"
//Attribute stored on PFObject to identify corresponding ManagedObject on SQLite, not used
#define kManagedObjectID                    @"objectID"
//The timestamp when MO gets updated from PO
#define kUpdatedDateKey                     @"updatedAt"
//Not used
#define kCreatedDateKey                     @"createdAt"
//events
extern NSString * const kEWSyncUploaded;

@interface EWSync : NSObject
/**
 * A dictionary holds pairs of {serverID: array of changedKeys};
 * use dictionary so it can be saved to UserDefaults
 */
@property (atomic, strong) NSDictionary *changedRecords;
@property BOOL isUploading;


#pragma mark - Instance
+ (EWSync *)sharedInstance;
- (void)setup;

#pragma mark - Status
+ (BOOL)isReachable;
+ (void)addToUpdatingMarks:(EWServerObject *)SO;
+ (BOOL)isUpdating:(EWServerObject *)SO;
+ (void)removeMOFromUpdating:(EWServerObject *)SO;
+ (BOOL)isDownloading:(EWServerObject *)SO;
+ (BOOL)isInUpdatingQueue:(EWServerObject *)SO;

#pragma mark - Server methods

/**
 The main method of server update/insert/delete.
 And save ManagedObject.
 @discussion Please do not call this method directly. It is scheduled when you call save method.
 */
//- (void)uploadToServer;
+ (void)saveImmediately;
/*
 Resume uploading at startup.
 **/
- (void)resumeUploadToServer;

/**
 *Update or Insert PFObject according to given ManagedObject
 *
 *1. First decide create or find parse object, handle error if necessary
 *
 *2. Update PO value and relation with given MO. (-updateValueFromManagedObject:) If related PO doesn't exist, create a PO async, and assign the newly created related PO to the relation.
 *
 *3. Save PO in background.
 *
 *4. When saved, assign parseID to MO
 *
 *5. Perform save callback block for this PO
 */
- (BOOL)updateParseObjectFromManagedObject:(NSManagedObject *)managedObject withError:(NSError **)error;

/**
 Find or delete ManagedObject by Entity and by Server Object
 @discussion This method only updates attributes of MO, not relationship. So it is only used to refresh value of specific MO
 */
//+ (NSManagedObject *)findOrCreateManagedObjectWithParseObjectID:(NSString *)objectId;

/**
 Access Global Save Callback dictionary and add blcok with key of ManagedObjectID
 */
+ (void)addParseSaveCallback:(PFObjectResultBlock)callback forManagedObjectID:(NSManagedObjectID *)objectID;
/**
 Add MO update completion callback
 */
+ (void)addUploadingCompletionBlocks:(EWManagedObjectSaveCallbackBlock)block forServerObject:(EWServerObject *)SO;

#pragma mark - Queue
//update queue
- (NSSet *)updateQueue;
- (void)appendUpdateQueue:(EWServerObject *)mo;
- (void)removeObjectFromUpdateQueue:(EWServerObject *)mo;
//insert queue
- (NSSet *)insertQueue;
- (void)appendInsertQueue:(EWServerObject *)mo;
- (void)removeObjectFromInsertQueue:(EWServerObject *)mo;
//uploading queue
- (NSSet *)workingQueue;
- (void)appendObjectToWorkingQueue:(EWServerObject *)mo;
- (void)removeObjectFromWorkingQueue:(EWServerObject *)mo;
//delete queue
- (NSSet *) deleteQueue;
- (void)appendObjectToDeleteQueue:(PFObject *)object;
- (void)removeObjectFromDeleteQueue:(PFObject *)object;
//download queue
- (void)appendToDownloadQueue:(EWServerObject *)mo;
//worker
- (NSSet *)getObjectFromQueue:(NSString *)queue;
- (void)appendObject:(EWServerObject *)mo toQueue:(NSString *)queue;
- (BOOL)contains:(EWServerObject *)mo inQueue:(NSString *)queue;

#pragma mark - CoreData
+ (EWServerObject *)findObjectWithClass:(NSString *)className withServerID:(NSString *)objectID error:(NSError **)error;
+ (EWServerObject *)findObjectWithClass:(NSString *)className withServerID:(NSString *)objectID inContext:(NSManagedObjectContext *)context error:(NSError **)error;
+ (BOOL)validateSO:(EWServerObject *)mo;
+ (BOOL)validateSO:(EWServerObject *)mo andTryToFix:(BOOL)tryFix;
+ (BOOL)checkAccess:(EWServerObject *)SO;

#pragma mark - Parse helper methods
//PO query
+ (NSArray *)findManagedObjectFromServerWithQuery:(PFQuery *)query saveInContext:(NSManagedObjectContext *)context error:(NSError **)error;
+ (void)findManagedObjectsFromServerInBackgroundWithQuery:(PFQuery *)query completion:(PFArrayResultBlock)block;
- (PFObject *)getCachedParseObjectWithClass:(NSString *)className ID:(NSString *)objectId;
- (void)setCachedParseObject:(PFObject *)PO;
/**
 1. Try to get PO from cache
 2. If not, then request a network call with query cache life of 1 hour
 */
- (PFObject *)getParseObjectWithClass:(NSString *)class ID:(NSString *)ID error:(NSError **)error;

/**
 Delete PFObject in server
 */
- (void)deleteParseObject:(PFObject *)parseObject;
@end
