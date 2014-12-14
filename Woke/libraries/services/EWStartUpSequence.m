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
#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "EWAccountManager.h"


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
    
    //watch for login event
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDataCheck) name:EWAccountManagerDidLoginNotification object:nil];
	
	return self;
}


#pragma mark - Login Check
- (void)loginDataCheck{
    DDLogVerbose(@"=== [%s] Logged in, performing login tasks.===", __func__);
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
	
    //continue upload to server if any
    DDLogVerbose(@"0. Continue uploading to server");
    [[EWSync sharedInstance] resumeUploadToServer];
	
	//fetch everyone
	DDLogVerbose(@"1. Getting everyone");
	[[EWPersonManager sharedInstance] getWakeesInBackgroundWithCompletion:NULL];
    
    //refresh current user
    DDLogVerbose(@"2. Register AWS push key");
    [EWServer registerAPNS];
    
    //check alarm, task, and local notif
    DDLogVerbose(@"3. Check alarm");
	[[EWAlarmManager sharedInstance] scheduleAlarm];
	
	DDLogVerbose(@"5. Check my social graph");
	//TODO
	
    DDLogVerbose(@"4. Check my unread media");//media also will be checked with background fetch
    [[EWMediaManager sharedInstance] checkMediaAssetsInBackground];
    
    //updating facebook friends
    DDLogVerbose(@"5. Updating facebook friends");
    //TODO: why?
//    [EWUserManager getFacebookFriends];
    
    //update facebook info
    //DDLogVerbose(@"6. Updating facebook info");
    //[EWUserManager updateFacebookInfo];
    
	DDLogVerbose(@"6. Check scheduled local notifications");
	[[EWAlarmManager sharedInstance] checkScheduledLocalNotifications];
    
    //Update my relations cancelled here because the we should wait for all sync task finished before we can download the rest of the relation
    NSLog(@"7. Refresh my media");
    [[EWMediaManager sharedInstance] mediaCreatedByPerson:[EWPerson me]];
	
	//location
	DDLogVerbose(@"8. Start location recurring update");
	[EWAccountManager registerLocation];
	
    
    //update data with timely updates
	//first time
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[@"start_date"] = [NSDate date];
	userInfo[@"count"] = @0;
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
    //this will run at the beginning and every 600s
    DDLogVerbose(@"Start sync service");
	
	//fetch everyone
	DDLogVerbose(@"[1] Getting everyone");
	[[EWPersonManager sharedInstance] getWakeesInBackgroundWithCompletion:NULL];
	
    //location
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		DDLogVerbose(@"[2] Start location recurring update");
		[EWAccountManager registerLocation];
	}
    
}

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






