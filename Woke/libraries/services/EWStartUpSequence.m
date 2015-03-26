//
//  EWStore.m
//  EarlyWorm
//
//  Created by Lei on 8/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWStartUpSequence.h"

#import "EWPersonManager.h"
#import "EWMediaManager.h"
#import "EWAlarmManager.h"
#import "EWWakeUpManager.h"
#import "EWServer.h"
#import "EWMedia.h"
#import "EWNotification.h"
#import "EWUIUtil.h"
#import "EWCachedInfoManager.h"
#import "EWBackgroundingManager.h"
#import "EWAccountManager.h"
#import "PFFacebookUtils.h"
#import "FBKVOController.h"
#import "NSDictionary+KeyPathAccess.h"
#import "NSTimer+BlocksKit.h"
#import "EWUtil.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "EWNotificationManager.h"

@interface EWStartUpSequence ()
@property (nonatomic, assign) BOOL dataChecked;
@end

@implementation EWStartUpSequence

+ (EWStartUpSequence *)sharedInstance{
    
    static EWStartUpSequence *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWStartUpSequence alloc] init];
    });
    return sharedStore_;
}

- (id)init{
	self = [super init];
    [NSDate mt_setFirstDayOfWeek:0];
    
    //load saved session info
    [EWSession sharedSession];
    
	//set up server sync
	[[EWSync sharedInstance] setup];
    
    //facebook
    [PFFacebookUtils initializeFacebook];
    
    //watch for login event
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDataCheck) name:EWDataDidSyncNotification object:nil];
    
    //observe updating MO
//    [self.KVOController observe:[EWSync sharedInstance] keyPath:@"managedObjectsUpdating" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
//        if ([EWSession sharedSession].isSyncingUser == NO && [EWSync sharedInstance].managedObjectsUpdating.allKeys.count == 0){
//            DDLogInfo(@"Sync data finished");
//            [[NSNotificationCenter defaultCenter] postNotificationName:EWDataDidSyncNotification object:nil];
//            [self loginDataCheck];
//        }
//        static NSTimer *timer;
//        [timer invalidate];
//        timer = [NSTimer bk_scheduledTimerWithTimeInterval:5 block:^(NSTimer *timer) {
//            DDLogInfo(@"The item still updating is: %@", [EWSync sharedInstance].managedObjectsUpdating);
//        } repeats:NO];
//    }];
	
	return self;
}

#pragma mark - Login startup sequence
- (void)startupSequence{
	DDLogVerbose(@"=== %s Logged in, performing login tasks.===", __func__);
	PFInstallation *currentInstallation = [PFInstallation currentInstallation];
	if (![currentInstallation[kUserID] isEqualToString: [EWPerson me].objectId]){
		currentInstallation[kUserID] = [EWPerson me].objectId;
		currentInstallation[kUsername] = [EWPerson me].username;
		[currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				DDLogVerbose(@"Installation %@ saved", currentInstallation.objectId);
			}else{
				DDLogVerbose(@"*** Installation %@ failed to save: %@", currentInstallation.objectId, error.description);
			}
		}];
	};
	
	
	//init backgrounding manager
	[EWBackgroundingManager sharedInstance];
	
	//fetch everyone
	DDLogVerbose(@"[1]. Getting everyone");
	[[EWPersonManager sharedInstance] getWakeesInBackgroundWithCompletion:NULL];
	
	//refresh current user
	DDLogVerbose(@"[2]. Register user notification");
	[[EWServer shared] requestNotificationPermissions];
	
	//location
	DDLogVerbose(@"[3]. Start location update");
	[[EWAccountManager shared] registerLocation];
    
    
    DDLogVerbose(@"[4]. Start cache management");
    [[EWCachedInfoManager shared] startAutoCacheUpdateForMe];
    
    DDLogVerbose(@"[5]. Start upload log files");
    [EWUtil uploadUpdatedLogFiles];
}

#pragma mark - Login Check
- (void)loginDataCheck{
    
    if (_dataChecked) {
        DDLogInfo(@"Skip data check as it is checked already!");
        return;
    }
    _dataChecked = YES;
    DDLogInfo(@"=======> start login data check work <========");
    
    
    //check alarm, task, and local notif
    DDLogVerbose(@"3. Check alarm");
    [[EWAlarmManager sharedInstance] scheduleAlarm];
    
    DDLogVerbose(@"4. Check scheduled local notifications");
    [[EWAlarmManager sharedInstance] checkScheduledLocalNotifications];
	
	//skip checking fb as it will check at beginning
    //DDLogVerbose(@"5. Updating facebook friends");
    //[[EWAccountManager sharedInstance] updateMyFacebookInfoWithCompletion:NULL];
	DDLogVerbose(@"5. Check redundant new media notifications");
	[[EWNotificationManager shared] checkNotifications];
	
    DDLogVerbose(@"6. Check unread medias");
    [[EWMediaManager sharedInstance] checkNewMediasWithCompletion:NULL];

    DDLogVerbose(@"7. Refresh my media");
    [[EWMediaManager sharedInstance] checkMediaFilesForPerson:[EWPerson me]];
    
    //resume upload
    DDLogVerbose(@"8. Check alarm");
    [[EWSync sharedInstance] resumeUploadToServer];
    
    //update data with timely updates
	//first time
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[@"start_date"] = [NSDate date];
	userInfo[@"count"] = @1;
	[NSTimer scheduledTimerWithTimeInterval:kServerUpdateInterval target:self selector:@selector(serverUpdate:) userInfo:userInfo repeats:YES];
	
}

- (void)serverUpdate:(NSTimer *)timer{

	if (timer) {
		NSInteger count;
		NSDate *start = timer.userInfo[@"start_date"];
		count = [(NSNumber *)timer.userInfo[@"count"] integerValue];
		DDLogVerbose(@"=== Server update started at %@ is running for the %ld times ===", start.date2detailDateString, (long)count);
		count++;
		timer.userInfo[@"count"] = @(count);
	}
	
    //services that need to run periodically
    if (![EWPerson me]) {
        return;
    }
	
	//fetch everyone
	DDLogVerbose(@"<1> Getting everyone");
	[[EWPersonManager sharedInstance] getWakeesInBackgroundWithCompletion:NULL];

    //location
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		DDLogVerbose(@"<2> Start location recurring update");
		[[EWAccountManager shared] registerLocation];
	}
    
    DDLogVerbose(@"<3>. Start upload log files");
    [EWUtil uploadUpdatedLogFiles];
}


#pragma mark - Sync user
- (void)syncUserWithCompletion:(ErrorBlock)block{
	EWAssertMainThread
	[[NSNotificationCenter defaultCenter] postNotificationName:kUserSyncStarted object:nil];
	[EWSession sharedSession].isSyncingUser = YES;
	NSString *const userKey = @"user";
	NSString *const deleteKey = @"delete";
	
	//generate info dic
	EWPerson *me = [EWPerson me];
	NSMutableDictionary *graph = [NSMutableDictionary new];
	//if no date available for me, it must be up to date.
	if (me.updatedAt) {
		graph[userKey] = @{me.serverID: me.updatedAt};
	} else {
		//Even though there might be pending changes, but the fact that local user missing update time is a sign of bad run from last session, therefore we should resync from server
		DDLogError(@"User %@ has no updatedAt, using 1970 time", me.name);
		graph[userKey] = @{me.objectId: [NSDate dateWithTimeIntervalSince1970:0]};
	}
	//get the updated objects
	NSSet *workingObjects = [EWSync sharedInstance].workingQueue;
	workingObjects = [workingObjects setByAddingObjectsFromSet:[EWSync sharedInstance].insertQueue];
	
	//enumerate
	[me.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relation, BOOL *stop) {
		if ([relation.destinationEntity.name isEqualToString:kSyncUserClass]) {
			//Discuss: we don't need to skip user class
			//return;
		}
		id objects = [me valueForKey:key];
		if (objects) {
			if ([relation isToMany]) {
				NSMutableDictionary *related = [NSMutableDictionary new];
				for (EWServerObject *SO in objects) {
					
					BOOL good = [SO validate];
					
					if (!SO.serverID) {
						DDLogError(@"Me->%@(%@) doesn't have serverID, add to upload queue.", key, SO.objectID);
						[SO uploadEventually];
					}
					else if ([workingObjects containsObject:SO]) {
						//has change, do not update from server, use current time
						//or has not updated to Server, meaning it will uploaded with newer data, use current time
						related[SO.serverID] = [NSDate date];
					}
					else if (SO.updatedAt && SO.updatedAt && good){
						related[SO.serverID] = SO.updatedAt;
					}
				}
				//add the graph to the info dic
				graph[key] = related;
			}
			else {
				//to-one relation
				graph[key] = @0;//get the key first
				EWServerObject *SO = (EWServerObject *)objects;
				BOOL good = [SO validate];
				if (!SO.serverID) {
					DDLogError(@"Me->%@(%@) doesn't have serverID, add to upload queue.", key, SO.objectID);
					[SO uploadEventually];
				}
				else if ([workingObjects containsObject:SO]) {
					//has change, do not update from server, use current time
					//or has not updated to Server, meaning it will uploaded with newer data, use current time
					graph[key] = @{SO.serverID: [NSDate date]};
				}
				else if (SO.serverID && SO.updatedAt && good){
					graph[key] = @{SO.objectId: SO.updatedAt};
				}
			}
		}else{
			graph[key] = @0;
		}
	}];
	
	//send to cloud
	[PFCloud callFunctionInBackground:@"syncUser" withParameters:graph block:^(NSDictionary *POGraph, NSError *error) {
		NSMutableDictionary *POGraphInfo = [NSMutableDictionary new];
		if (error) {
			[EWSession sharedSession].isSyncingUser = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:kUserSyncCompleted object:nil];
			block(error);
			return;
		}
		//expecting a dictionary of objects needed to update
		//return graph level: 1) relation name 2) Array of PFObjects or PFObject
		//create a list of POs to pin
		NSMutableSet *POtoPin = [NSMutableSet new];
		[POGraph enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
			if ([key isEqualToString:userKey]) {
				POGraphInfo[key] = @"me";
				[[EWSync sharedInstance] setCachedParseObject:obj];
                [EWSync sharedInstance].managedObjectsUpdating = [[EWSync sharedInstance].managedObjectsUpdating setValue:@"syncData" forImmutableKeyPath:@[me.serverID]];
				[me assignValueFromParseObject:obj];
				return;
			}
            else if ([key isEqualToString:deleteKey]) {
				POGraphInfo[key] = obj;
				//delete all objects in this Dictionary
				DDLogInfo(@"Deleting objects %@", obj);
				[(NSDictionary *)obj enumerateKeysAndObjectsUsingBlock:^(NSString *objectId, NSString *relationName, BOOL *stop2) {
					NSRelationshipDescription *relation =  me.entity.relationshipsByName[relationName];
					NSString *className = relation.destinationEntity.name;
					EWServerObject *MO = (EWServerObject *)[NSClassFromString(className) MR_findFirstByAttribute:kParseObjectID withValue:objectId inContext:mainContext];
					if (relation.isToMany) {
						NSMutableSet *related = [me valueForKey:relationName];
						[related removeObject:MO];
						[me setValue:related forKey:relationName];
					} else {
						[me setValue:nil forKey:relationName];
					}
				}];
				return;
            }
            else if ([key isEqualToString:@"mediaFiles"]) {
                POGraphInfo[key] = [(NSArray *)[obj valueForKey:kParseObjectID] string];
                DDLogInfo(@"Pin %@ to cache", key);
                [POtoPin addObjectsFromArray:obj];
                return;
            }
			NSRelationshipDescription *relation = me.entity.relationshipsByName[key];
			if (!relation && ![obj isKindOfClass:[PFObject class]]) {
				DDLogError(@"Unecpected value from server: %@(%@)", key, obj);
				return;
			}
			//save PO first
			if (relation.isToMany) {
				POGraphInfo[key] = [(NSArray *)[obj valueForKey:kParseObjectID] string];
				DDLogInfo(@"Pin %@ to cache", key);
				[POtoPin addObjectsFromArray:obj];
			}else{
				POGraphInfo[key] = [(PFObject *)obj valueForKey:kParseObjectID];
				[[EWSync sharedInstance] setCachedParseObject:(PFObject *)obj];
				[POtoPin addObject:obj];
			}
		}];
		TICK
		[PFObject pinAll:POtoPin.allObjects error:&error];
		if (error) DDLogError(@"Failed to Pin returned PO: %@", error);
		
		DDLogInfo(@"Server returned sync info: %@", POGraphInfo);
		
		//save me first so the sql has the me object for other threads
		[me saveToLocal];
		
		[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
			EWPerson *localMe = [me MR_inContext:localContext];
			[POGraph enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
				
				NSRelationshipDescription *relation = localMe.entity.relationshipsByName[key];
				if (!relation) return;
				
				//decide whether to update the MO async
				//Note: download async at beginning is proved to b
				BOOL sync = YES;//[kUserRelationSyncRequired containsObject:key];
				
				//update SO
				if (relation.isToMany) {
					NSArray *objects = (NSArray *)obj;
					NSMutableSet *relatedSO = [localMe mutableSetValueForKey:key];
					for (PFObject *PO in objects) {
						if(!PO.isDataAvailable) {
							DDLogError(@"Returned PO without data: %@", PO);
							[PO fetch];
						}
						EWServerObject *MO;
						if ([relation.destinationEntity.name isEqualToString:kSyncUserClass]) {
							MO = [PO managedObjectInContext:localContext option:EWSyncOptionUpdateAttributesOnly completion:nil];
							DDLogInfo(@"Synced properties for %@(%@)", MO.entity.name, MO.serverID);
						}else if (sync){
							MO = [PO managedObjectInContext:localContext option:EWSyncOptionUpdateRelation completion:nil];
							DDLogInfo(@"Synced all for %@(%@)", MO.entity.name, MO.serverID);
                        }else {
                            [EWSync sharedInstance].managedObjectsUpdating = [[EWSync sharedInstance].managedObjectsUpdating setValue:@"syncData" forImmutableKeyPath:@[PO.objectId]];
							MO = [PO managedObjectInContext:localContext option:EWSyncOptionUpdateAsync completion:^(EWServerObject *SO, NSError *error) {
								DDLogInfo(@"Synced in background %@(%@)", SO.entity.name, SO.serverID);
							}];
						}
						if (sync && ![MO validate]) {
							DDLogError(@"MO %@(%@) is not valid after download, delete to server!", MO.entity.name, MO.serverID);
							[MO remove];
						}
						else if (![relatedSO containsObject:MO]) {
							//add relation
							[relatedSO addObject:MO];
							[localMe setValue:relatedSO.copy forKey:key];
							DDLogVerbose(@"+++> Added relation Me->%@(%@)", key, PO.objectId);
						}
					}
				}else{
					//to one
					PFObject *PO = (PFObject *)obj;
					EWServerObject *MO;
					
					if(!PO.isDataAvailable) {
						DDLogError(@"Returned PO without data: %@", PO);
						[PO fetch];
					}
					if ([relation.destinationEntity.name isEqualToString:kSyncUserClass]) {
						MO = [PO managedObjectInContext:localContext option:EWSyncOptionUpdateAttributesOnly completion:nil];
						DDLogInfo(@"Synced properties for %@(%@)", MO.entity.name, MO.serverID);
					}else if (sync){
						MO = [PO managedObjectInContext:localContext option:EWSyncOptionUpdateRelation completion:nil];
						DDLogInfo(@"Synced all for %@(%@)", MO.entity.name, MO.serverID);
					}else {
                        [EWSync sharedInstance].managedObjectsUpdating = [[EWSync sharedInstance].managedObjectsUpdating setValue:@"syncData" forImmutableKeyPath:@[PO.objectId]];
						MO = [PO managedObjectInContext:localContext option:EWSyncOptionUpdateAsync completion:^(EWServerObject *SO, NSError *error) {
							DDLogInfo(@"Synced in background %@(%@)", SO.entity.name, SO.serverID);
						}];
					}
					
					if (![MO validate]) {
						DDLogError(@"MO %@(%@) is not valid after download, discard", MO.entity.name, MO.serverID);
						[MO remove];
					}
					else if ([localMe valueForKey:key] != MO) {
						DDLogVerbose(@"+++> Set relation Me->%@(%@)", key, MO.objectId);
						[localMe setValue:MO forKey:key];
					}
				}
			}];
			
			//save to local so the updatedAt is assigned
            [localMe saveToLocal];
			
        } completion:^(BOOL contextDidSave, NSError *error2) {
            DDLogDebug(@"========> Finished user syncing <=========");
            TOCK
			[EWSession sharedSession].isSyncingUser = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:kUserSyncCompleted object:error2];//TODO: remove this
            block(error2);
			if (error2) {
				NSString *str = [NSString stringWithFormat:@"========> Failed to save synced user \n This is a very serious error: %@", error2.description];
				DDLogError(str);
				EWAlert(str);
			}
		}];
	}];
}

#pragma mark - Helper
+ (void)deleteDatabase{
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:[MagicalRecord defaultStoreName]];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
	
    if (error) {
        NSLog(@"An error has occurred while deleting %@", storeURL);
        NSLog(@"Error description: %@", error.description);
    }
}

@end






