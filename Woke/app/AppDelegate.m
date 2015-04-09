//
//  AppDelegate.m
//  Woke
//
//  Created by Zitao Xiong on 11/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

//model
#import "AppDelegate.h"
#import "EWStartUpSequence.h"
#import "EWAccountManager.h"
#import "EWSession.h"
#import "EWLoginGateViewController.h"
#import "EWMainViewController.h"
#import "EWStyleController.h"
#import "EWServer.h"
//utility
#import "Crashlytics.h"
#import "EWUIUtil.h"
#import "EWUtil.h"
#import "FBSession.h"
#import "FBAppCall.h"
#import "PFFacebookUtils.h"
#import "BlocksKit+UIKit.h"
#import "ATConnect.h"

UIViewController *rootViewController;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	//disable DYCI
    //[NSClassFromString(@"SFDynamicCodeInjection") performSelector:@selector(disable)];
	
    // Enable Crash Reporting
	initLogging();
	
	//add testing panel callout gesture
	[EWUtil addTestGesture];
	
	//crashlytics
	[Crashlytics startWithAPIKey:@"6ec9eab6ca26fcd18d51d0322752b861c63bc348"];
	
	// Parse
    [Parse enableLocalDatastore];
	[Parse setApplicationId:kParseApplicationId clientKey:kParseClientKey];
	
	//apptentive
	[ATConnect sharedConnection].apiKey = kATConnectKey;
	
	//UI
	[EWStyleController applySystemStyle];
	self.window.tintColor = [UIColor whiteColor];
	
    //Init startup sequence and save launch options
    [EWStartUpSequence sharedInstance].launchOptions = launchOptions;
    
    //Login process: https://www.lucidchart.com/documents/edit/47d70f1c-5306-dbab-81ce-6d480a005610
    if ([EWAccountManager isLoggedIn]) {
        [[EWAccountManager sharedInstance] fetchCurrentUser:[PFUser currentUser]];
        [[EWAccountManager sharedInstance] refreshEverythingIfNecesseryWithCompletion:^(NSError *error) {
            DDLogInfo(@"Logged in Core Data user: %@", [EWPerson me].name);
            if (error) {
                DDLogError(@"Logged in Core Data user With error: %@", error);
            }
        }];
        
        //show main view controller
        EWMainViewController *vc = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWMainViewController"];
        [[UIWindow mainWindow].rootNavigationController setViewControllers:@[vc]];
    }
    else {
        //show login view controller
        EWLoginGateViewController *vc = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWLoginGateViewController"];
        [[UIWindow mainWindow].rootNavigationController setViewControllers:@[vc]];
        
    }
    
    //finish launching
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	NSUInteger unreadCount = [EWPerson myUnreadNotifications].count;
	unreadCount += [ATConnect sharedConnection].unreadMessageCount;
	DDLogVerbose(@"Set app bedge count to %lu", (long unsigned)unreadCount);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    rootViewController = self.window.rootViewController;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    // Logs 'install' and 'app activate' App Events.
    [FBAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Facebook
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    BOOL handled_1 = [FBSession.activeSession handleOpenURL:url];
    BOOL handled_2 =  [FBAppCall handleOpenURL:url sourceApplication:sourceApplication fallbackHandler:^(FBAppCall *call) {
        DDLogError(@"Unhandled deep link: %@", url);
        // Here goes the code to handle the links.
        // Use the links to show a relevant view of your app to the user
        [EWUIUtil showFailureHUBWithString:@"Facebook invitation failed"];
    }];
    
    return handled_1 && handled_2;
}

#pragma mark - User notification
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{
    UIUserNotificationType type = notificationSettings.types;
    DDLogVerbose(@"Application registered user notification (%lu)", type);
	if (notificationSettings.types != UIUserNotificationTypeNone) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kUserNotificationRegistered object:notificationSettings];
	}else{
		DDLogError(@"Failed to register user notification");
		[UIAlertView bk_showAlertViewWithTitle:@"Something wrong" message:@"Woke failed to schedule alarm Notification. Please fix it in Setting." cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Fix"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
			if (buttonIndex == 1) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
			}
		}];
	}
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	[[EWServer shared] registerPushNotificationWithToken:deviceToken];
	[[ATConnect sharedConnection] addParseIntegrationWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	if (error.code != 3000) {
		[UIAlertView bk_showAlertViewWithTitle:@"Something wrong" message:@"Woke failed to schedule alarm Notification. Please fix it in Setting." cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Fix"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
			if (buttonIndex == 1) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
			}
		}];
    }
    DDLogError(@"Failed to register push: %@", error);
}

#pragma mark - Handle notification
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    [EWServer handleLocalNotification:notification.userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    [EWServer handlePushNotification:userInfo];
	[[ATConnect sharedConnection] didReceiveRemoteNotification:userInfo fromViewController:[EWUIUtil topViewController]];
	
	DDLogInfo(@"Activated app from background fetch");
	[[NSNotificationCenter defaultCenter] postNotificationName:kReceivedRemoteNotification object:application];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		completionHandler(UIBackgroundFetchResultNewData);
	});
}

#pragma mark - Background fetch method (this is called periodocially
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
	DDLogVerbose(@"======== Launched in background due to background fetch event ==========");
	//enable audio session and keep audio port
	[[NSNotificationCenter defaultCenter] postNotificationName:kBackgroundFetchStarted object:application];
	
	//check media assets
	//BOOL newMedia = [[EWMediaManager sharedInstance] checkMediaAssets];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//		DDLogVerbose(@"Returned background fetch handler with %@", newMedia?@"new data":@"no data");
//		if (newMedia) {
//			completionHandler(UIBackgroundFetchResultNewData);
//		}else{
//			completionHandler(UIBackgroundFetchResultNoData);
//		}
			completionHandler(UIBackgroundFetchResultNewData);
	});
	
}
@end
