//
//  EWDefines.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-28.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWBlockTypes.h"

//System
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define iOS7 ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)

#define kAppName                        @"Woke"
#define kAppVersion                     @"0.8.0"
#define BACKGROUND_TEST                 YES

#define kCustomWhite                    EWSTR2COLOR(@"#F5F5F5")
#define kCustomGray                     EWSTR2COLOR(@"48494B")
#define kColorMediumGray                EWSTR2COLOR(@"7e7e7e")
#define kCustomLightGray                EWSTR2COLOR(@"#DDDDDD")


#define ringtoneNameList                @[@"Autumn Spring.caf", @"Daybreak.caf", @"Drive.caf", @"Parisian Dream.caf", @"Sunny Afternoon.caf", @"Tropical Delight.caf"]

// Keys
#define kParsePushUrl                   @"https://api.parse.com/1/push"
#define kParseUploadUrl                 @"https://api.parse.com/1/"
#define kParseApplicationId             @"QHWs9RBxMxmuzMmOB9QliQVKBqOLhifPKyJIGrXx"
#define kParseClientKey                 @"PUCluYbG6LnPOfvJeYrhh2sNYX4ETffuPS4u65fJ"
#define kParseRestAPIId                 @"ZtAlif0L5UiL1HzXGS71XfI6dxyTJWXgis37t2oo"
#define kParseMasterKey                 @"iEjKEePThBb4KxJVj64o3nbkBGYrGzm6NPiFaFoN"
#define WokeUserID                      @"CvCaWauseD"
#define KATConnectKey                   @"61c58f4a6f819d0f209606bdf5e9eeadabfc73529dba358cd079df0dc6dd1102"



// 任务宏
#define EW_DEBUG_LEVEL                  3//defined logging level
#define LOCALSTR(x)                     NSLocalizedString(x,nil)
#ifdef DEBUG//work only on debug
#define EWAlert(str)                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#else
#define EWAlert(str)					NSLog(str)
#endif
#define UIColorFromHex(rgbValue)        [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define TICK                            NSDate *startTime = [NSDate date];
#define TOCK                            NSLog(@"Time: %f", -[startTime timeIntervalSinceNow]);
#define EWAssertMainThread              NSAssert([NSThread isMainThread], @"%s not in main thread", __FUNCTION__);
#define NoneErrorCreate(error)			if(!error) {NSError __autoreleasing *err; error = &err;}

//Account Management
extern NSString * const EWAccountDidLoginNotification;
extern NSString * const EWAccountDidLogoutNotification;
extern NSString * const EWDataDidSyncNotification;

//Global parameters
#define nWeeksToSchedule				1
#define nLocalNotifPerAlarm             5
#define kAlarmTimerCheckInterval        90 //10 min
#define alarmInterval                   600 //10 min
#define kMaxWakeTime                    3600 // 60min
#define kMaxEalyWakeInterval            1.5*3600
#define kMediaPlayInterval              5
#define kSocialGraphUpdateInterval      3600*24*7
#define kMaxVoicePerTask                3
#define kServerUpdateInterval			3600//2 hours
#define kCollectionViewCellWidth		80

//DEFAULT DATA
#define defaultAlarmTimes               @[@8.00, @8.00, @8.00, @8.00, @8.00, @8.00, @8.00]
#define sleepDurations					@[@6, @6.5, @7.5, @8, @8.5, @9, @9.5, @10, @10.5, @11, @11.5, @12]
#define kUserDefaults                   @{@"DefaultTone": @"Autumn Spring.caf", @"SleepDuration":@8.0, kSocialLevel:kSocialLevelEveryone, @"FirstTime":@YES, @"SkipTutorial":@NO, @"buzzSound":@"default", @"BedTimeNotification":@YES}
#define kSocialLevel                    @"SocialLevel"
#define kSocialLevelFriends             @"Friends_only"
#define kSocialLevelFriendCircle        @"Friend_Circle"
#define kSocialLevelEveryone            @"Everyone"

//user defaults key
#define kPushTokenDicKey                @"push_token_dic" //the key for local defaults to get the array of tokenByUser dict
#define kUserLoggedInUserKey            @"user"
#define kAWSEndPointDicKey              @"AWS_EndPoint_dic"
#define kAWSTopicDicKey                 @"AWS_Topic_dic"
#define kLastChecked                    @"last_checked"//stores the last checked task
//#define kSavedAlarms                    @"saved_alarms"

#define onePixel  (1.0 / [UIScreen mainScreen].nativeScale)
#pragma mark - User / External events

//============> App wide events <==============
extern NSString * const kWakeStartNotification;//start wake
extern NSString * const kWokeNotification;//finished wake
extern NSString * const kSleepNotification;
extern NSString * const kNewMediaNotification;
extern NSString * const kNewTimerNotification;
extern NSString * const kUserNotificationRegistered;
extern NSString * const kUserLocationUpdated;

//sleep
extern NSString * const kSleepDuration;
extern NSString * const kBedTimeNotification;

//wakeUpManager
#define kPushAlarmID					@"alarm_server_ID"
#define kLocalAlarmID					@"alarm_local_ID"
#define kActivityLocalID                @"activity_object_ID"

//Notification types
extern NSString * const kNotificationTypeFriendRequest;
extern NSString * const kNotificationTypeFriendAccepted;
extern NSString * const kNotificationTypeSystemNotice;
extern NSString * const kNotificationTypeNewMedia;
extern NSString * const kNotificationTypeNewUser;

//alarm store
extern NSString * const kAlarmNew;//key: alarm
extern NSString * const kAlarmStateChanged;//key: alarm
extern NSString * const kAlarmTimeChanged;//key: alarm
extern NSString * const kAlarmDelete;//key: tasks
extern NSString * const kAlarmChanged;//key: alarm
extern NSString * const kAlarmToneChanged;//key: alarm
extern NSString * const kAlarmStatementChanged;//key: alarm

//push
extern NSString * const kADIDKey;//key for ADID
extern NSString * const kPushAPNSRegisteredNotification;

//Notification key
extern NSString * const kLocalNotificationTypeKey;
extern NSString * const kLocalNotificationTypeAlarmTimer;
extern NSString * const kLocalNotificationTypeReactivate;
extern NSString * const kLocalNotificationTypeSleepTimer;

//push
extern NSString * const kPushType;
extern NSString * const kPushTypeAlarmTimer;
extern NSString * const kPushTypeBroadcast;
extern NSString * const kPushTypeMedia;
extern NSString * const kPushTypeNotification;

//media
extern NSString * const kPushMediaType;
extern NSString * const kPushMediaTypeBuzz;
extern NSString * const kPushMediaTypeVoice;
extern NSString * const kPushPersonID;
extern NSString * const kPushMediaID;

//notification
extern NSString * const kPushNofiticationID;


//Cached Info
extern NSString * const kCachedFriends;
extern NSString * const kCachedAlarmTimes;
extern NSString * const kCachedStatements;


// ATConnect
extern NSString * const kLoginSuccess;
extern NSString * const kWakeupSuccess;
extern NSString * const kRecordVoiceSuccess;


