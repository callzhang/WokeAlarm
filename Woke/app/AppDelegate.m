//
//  AppDelegate.m
//  Woke
//
//  Created by Zitao Xiong on 11/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "AppDelegate.h"
#import "EWStartUpSequence.h"
#import "FBSession.h"
#import "FBAppCall.h"
#import "PFFacebookUtils.h"
#import "EWAccountManager.h"
#import "EWSession.h"
#import "EWLoginGateViewController.h"
#import "EWMainViewController.h"

#import <CrashlyticsLogger.h>
#import <ParseCrashReporting/ParseCrashReporting.h>
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "EWStyleController.h"
#import "EWServer.h"
#import "BlocksKit.h"
#import "BlocksKit+UIKit.h"
#import "FBTweakViewController.h"
#import "FBTweakStore.h"

UIViewController *rootViewController;

@interface AppDelegate ()<FBTweakViewControllerDelegate, UIAlertViewDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef DEBUG
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    
    DDTTYLogger *log = [DDTTYLogger sharedInstance];
    [DDLog addLogger:log];
    
    // we also enable colors in Xcode debug console
    // because this require some setup for Xcode, commented out here.
    // https://github.com/CocoaLumberjack/CocoaLumberjack/wiki/XcodeColors
    [log setColorsEnabled:YES];
    [log setForegroundColor:[UIColor redColor] backgroundColor:nil forFlag:LOG_FLAG_ERROR];
    [log setForegroundColor:[UIColor colorWithRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0] backgroundColor:nil forFlag:LOG_FLAG_WARN];
    [log setForegroundColor:[UIColor orangeColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
    //white for debug
    [log setForegroundColor:[UIColor darkGrayColor] backgroundColor:nil forFlag:LOG_FLAG_VERBOSE];
    
    //file logger
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;//keep a week's log
    [DDLog addLogger:fileLogger];
    
    //crashlytics logger
    [DDLog addLogger:[CrashlyticsLogger sharedInstance]];
#endif
    
    self.window.tintColor = [UIColor whiteColor];
    
    // Enable Crash Reporting
    [ParseCrashReporting enable];
    [Parse setApplicationId:kParseApplicationId clientKey:kParseClientKey];
    
    //[EWStartUpSequence deleteDatabase];
    
    [EWStyleController applySystemStyle];
    //watch for login
    [EWStartUpSequence sharedInstance];
    
    //Login process: https://www.lucidchart.com/documents/edit/47d70f1c-5306-dbab-81ce-6d480a005610
    if ([EWAccountManager isLoggedIn]) {
        [[EWAccountManager sharedInstance] fetchCurrentUser:[PFUser currentUser]];
        [[EWAccountManager sharedInstance] refreshEverythingIfNecesseryWithCompletion:^(NSError *error) {
            DDLogInfo(@"Logged in Core Data user: %@", [EWPerson me].name);
            if (error) {
                DDLogError(@"With error: %@", error);
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
    
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        FBTweakViewController *viewController = [[FBTweakViewController alloc] initWithStore:[FBTweakStore sharedInstance]];
        viewController.tweaksDelegate = self;
        [[[UIWindow mainWindow] rootViewController] presentViewController:viewController animated:YES completion:nil];
    }];
    longGesture.numberOfTouchesRequired = 2;
    longGesture.minimumPressDuration = 2;
    
    [[UIWindow mainWindow].rootViewController.view addGestureRecognizer:longGesture];
    
    return YES;
}

- (void)tweakViewControllerPressedDone:(FBTweakViewController *)tweakViewController {
    [tweakViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    rootViewController = self.window.rootViewController;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
    BOOL handled_2 =  [FBAppCall handleOpenURL:url
                             sourceApplication:sourceApplication
                                   withSession:[PFFacebookUtils session]];
    
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
        [[[UIAlertView alloc] initWithTitle:@"Something wrong" message:@"Woke failed to schedule alarm Notification. Please fix it in Setting." delegate:self cancelButtonTitle:@"Not now" otherButtonTitles:@"OK", nil] show];
	}
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	[[EWServer shared] registerPushNotificationWithToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code != 3000) {
        [[[UIAlertView alloc] initWithTitle:@"Something wrong" message:@"Woke failed to schedule alarm Notification. Please fix it in Setting." delegate:self cancelButtonTitle:@"Not now" otherButtonTitles:@"OK", nil] show];
    }
    DDLogError(@"Failed to register push: %@", error);
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"OK"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}
@end
