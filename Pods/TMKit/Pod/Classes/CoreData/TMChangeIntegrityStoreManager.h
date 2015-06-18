//
//  TMChangeIntegrityStoreManager.h
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

#import <Foundation/Foundation.h>
@import CoreData;

@interface TMChangeIntegrityStoreManager : NSObject

+ (instancetype)sharedChangeIntegrityStoreManager;

#pragma mark - Deletion Integrity methods

+ (BOOL)containsDeletionRecordForSyncID:(NSString *)ticdsSyncID;
+ (void)addSyncIDToDeletionIntegrityStore:(NSString *)ticdsSyncID;
+ (void)removeSyncIDFromDeletionIntegrityStore:(NSString *)ticdsSyncID;

#pragma mark - Insertion Integrity methods

+ (BOOL)containsInsertionRecordForSyncID:(NSString *)ticdsSyncID;
+ (void)addSyncIDToInsertionIntegrityStore:(NSString *)ticdsSyncID;
+ (void)removeSyncIDFromInsertionIntegrityStore:(NSString *)ticdsSyncID;

#pragma mark - Change Integrity methods

+ (BOOL)containsChangedAttributeRecordForKey:(id)key withValue:(id)value syncID:(NSString *)ticdsSyncID;
+ (void)addChangedAttributeValue:(id)value forKey:(id)key toChangeIntegrityStoreForSyncID:(NSString *)ticdsSyncID;
+ (void)removeChangedAttributesEntryFromChangeIntegrityStoreForSyncID:(NSString *)ticdsSyncID;

#pragma mark - Undo Integrity methods

+ (void)storeTICDSSyncID:(NSString *)ticdsSyncID forManagedObjectID:(NSManagedObjectID *)managedObjectID;
+ (NSString *)ticdsSyncIDForManagedObjectID:(NSManagedObjectID *)managedObjectID;
@end
