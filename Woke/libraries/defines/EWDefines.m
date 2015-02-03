//
//  EWDefines.m
//  Woke
//
//  Created by Zitao Xiong on 1/22/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWDefines.h"

NSString *const kNewMediaNotification = @"media_event";
NSString *const EWAccountDidLoginNotification = @"EWAccountDidLoginNotification";
NSString *const EWAccountDidLogoutNotification = @"EWAccountDidLogoutNotification";
NSString *const kWakeStartNotification = @"wake_time";
NSString * const kWokeNotification = @"woke";
NSString * const kSleepNotification = @"Sleep";
NSString * const kNewTimerNotification = @"alarm_timer";
NSString * const kUserNotificationRegistered = @"local_notification_registered";

NSString * const kSleepDuration = @"SleepDuration";
NSString * const kBedTimeNotification = @"BedTimeNotification";

//notification types
NSString * const kPushNofiticationID = @"notificationID";
NSString * const kNotificationTypeFriendRequest = @"friendship_request";
NSString * const kNotificationTypeFriendAccepted = @"friendship_accepted";
NSString * const kNotificationTypeSystemNotice = @"notice";
NSString * const kNotificationTypeNewMedia = @"new_media";
NSString * const kNotificationTypeNewUser = @"new_user";

//alarm
NSString * const kAlarmNew = @"EWAlarmNew"; //key: alarm
NSString * const kAlarmStateChanged = @"EWAlarmStateChanged";//key: alarm
NSString * const kAlarmTimeChanged = @"EWAlarmTimeChanged";//key: alarm
NSString * const kAlarmDelete = @"EWAlarmDelete";//key: tasks
NSString * const kAlarmChanged = @"EWAlarmChanged"; //key: alarm
NSString * const kAlarmToneChanged = @"EWAlarmToneChanged"; //key: alarm
NSString * const kAlarmStatementChanged = @"EWAlarmStatementChanged"; //key: alarm

//push
NSString * const kADIDKey = @"ADID"; //key for ADID
NSString * const kPushAPNSRegisteredNotification = @"APNSRegistered";

//Notification key
NSString * const kLocalNotificationTypeKey = @"type";
NSString * const kLocalNotificationTypeAlarmTimer = @"alarm_timer";
NSString * const kLocalNotificationTypeReactivate = @"reactivate";
NSString * const kLocalNotificationTypeSleepTimer = @"sleep_timer";

//push
NSString * const kPushType = @"type";
NSString * const kPushTypeAlarmTimer = @"timer";
NSString * const kPushTypeBroadcast = @"broadcast";
NSString * const kPushTypeMedia = @"media";
NSString * const kPushTypeNotification = @"notice";

//media
NSString * const kPushMediaType = @"media_type";
NSString * const kPushMediaTypeBuzz = @"buzz";
NSString * const kPushMediaTypeVoice = @"voice";
NSString * const kPushPersonID = @"person";
NSString * const kPushMediaID = @"media";


//Cached Info
NSString * const kCachedFriends = @"friends";
NSString * const kCachedAlarmTimes = @"alarm_schedule";
NSString * const kCachedStatements = @"statements";


// ATConnect
NSString * const kLoginSuccess = @"login_success";
NSString * const kWakeupSuccess = @"wake_success";
NSString * const kRecordVoiceSuccess = @"record_success";