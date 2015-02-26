//
//  EWStore.h
//  EarlyWorm
//
//  Data Manager manages all data related tasks, such as login check and data synchronization with server
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Woke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWSync.h"

#define kUserRelationSyncRequired   @[@"alarms", @"socialGraph", @"activities"]//list of relations that must be synced before the rest of the application execution
#define kUserSyncStarted			@"user_sync_started"
#define kUserSyncCompleted			@"user_sync_completed"

@interface EWStartUpSequence : NSObject
@property (nonatomic, retain) NSDate *lastChecked;//The date that last sync with server
+ (EWStartUpSequence *)sharedInstance;
- (void)startupSequence;
- (void)loginDataCheck;


// sync user
/**
 *  Sync user at start up. Send local object ID and updatedAt. When returned from server, update all returned objects.
 *
 *  @param info Dictionary with first level: 1) relation 2) {objectID: updatedAt}
 */
- (void)syncUserWithCompletion:(ErrorBlock)block;


//helper
+ (void)deleteDatabase;
@end
