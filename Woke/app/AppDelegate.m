//
//  AppDelegate.m
//  Woke
//
//  Created by Zitao Xiong on 11/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "AppDelegate.h"
#import "EWUtil.h"
#import "EWSync.h"
#import "EWStartUpSequence.h"
#import "FBSession.h"
#import "FBAppCall.h"
#import "PFFacebookUtils.h"
#import "EWAccountManager.h"
#import "EWSession.h"
#import "EWLoginGateViewController.h"
#import "EWMainViewController.h"

#import <CrashlyticsLogger.h>
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "EWStyleController.h"

UIViewController *rootViewController;

@interface AppDelegate ()

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
    
    [Parse setApplicationId:kParseApplicationId clientKey:kParseClientKey];
    
    //[EWStartUpSequence deleteDatabase];
    
    [EWStyleController applySystemStyle];
    //watch for login
    [EWStartUpSequence sharedInstance];
    
#ifdef caoer115
    EWMainViewController *vc = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWMainViewController"];
    [[UIWindow mainWindow].rootNavigationController setViewControllers:@[vc]];
#else
    if ([EWAccountManager isLoggedIn]) {
        [[EWAccountManager sharedInstance] fetchCurrentUser:[PFUser currentUser]];
        [[EWAccountManager sharedInstance] refreshEverythingIfNecesseryWithCompletion:^(BOOL isNewUser, NSError *error) {
            DDLogInfo(@"Logged in Core Data user: %@", [EWPerson me].name);
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
#endif
    return YES;
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
@end
