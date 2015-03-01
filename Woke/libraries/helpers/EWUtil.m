//
//  EWUtil.m
//  EarlyWorm
//
//  Created by Lei on 8/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//
//  This class serves as the basic file input/output class that handles file namagement and memory management

#import "EWUtil.h"
#import <CrashlyticsLogger.h>
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "FBTweak.h"
#import "FBTweakInline.h"
#import "FBTweakViewController.h"
#import "EWUIUtil.h"
#import "BlocksKit.h"
#import "BlocksKit+UIKit.h"
#import "UIGestureRecognizer+BlocksKit.h"
#import "UIViewController+Blur.h"
//#import <AdSupport/ASIdentifierManager.h>

@interface EWUtil()<FBTweakViewControllerDelegate>

@end

@implementation EWUtil
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS(EWUtil)
+ (NSString *)UUID{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    return uuid;
}
	
//+ (NSString *)ADID{
//    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
//    return adId;
//}

+(void)clearMemory{
    //
}

+ (NSDictionary *)timeFromNumber:(double)number{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    NSInteger hour = (NSInteger)floor(number);
    NSInteger minute = (NSInteger)round((number - hour)*100);
    dic[@"hour"] = [NSNumber numberWithInteger:hour];
    dic[@"minute"] = [NSNumber numberWithInteger: minute];
    return dic;
}

+ (double)numberFromTime:(NSDictionary *)dic{
    double hour = [(NSNumber *)dic[@"hour"] doubleValue];
    double minute = [(NSNumber *)dic[@"minute"] doubleValue];
    double number = hour + minute/100;
    return number;
}


+ (BOOL) isMultitaskingSupported {
    
    BOOL result = NO;
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]){
        result = [[UIDevice currentDevice] isMultitaskingSupported];
    }
    return result;
}

+ (void)initLogging{
    initLogging();
}

+ (void)addTestGesture{
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        [EWUtil showTweakPanel];
    }];
    longGesture.numberOfTouchesRequired = 2;
    longGesture.minimumPressDuration = 2;
    [[UIWindow mainWindow] addGestureRecognizer:longGesture];
}

+ (void)showTweakPanel{
    FBTweakViewController *viewController = [[FBTweakViewController alloc] initWithStore:[FBTweakStore sharedInstance]];
    viewController.tweaksDelegate = [EWUtil shared];
    UIViewController *topController = [EWUIUtil topViewController];
    if (![topController isKindOfClass:NSClassFromString(@"_FBTweakCategoryViewController")]) {
        [topController presentViewController:viewController animated:YES completion:nil];
        //[topController presentViewControllerWithBlurBackground:viewController];
    }
}


- (void)tweakViewControllerPressedDone:(FBTweakViewController *)tweakViewController {
    [tweakViewController dismissViewControllerAnimated:YES completion:nil];
}
@end

@implementation NSArray(Extend)

- (NSString *)string{
    NSMutableString *string = [NSMutableString stringWithString:@""];
    for (NSString *key in self) {
        [string appendFormat:@"%@, ", key];
    }
    return [string substringToIndex:string.length-2];
}

@end


void initLogging(){
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
}
