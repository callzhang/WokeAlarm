//
//  EWNotificationManager.h
//  Woke
//
//  Created by Lei on 4/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNotificationCompleted      @"notification_completed"
#define kNotificationNew            @"notification_new"

@class EWNotification, EWMedia, EWPerson;

@interface EWNotificationManager : NSObject <UIAlertViewDelegate>

GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWNotificationManager)

/**
 *  Handle EWNotification from push notifiaction
 *
 *  @param payload The Dictionary from push notifiaction
 */
- (void)handleNotificatoinFromPush:(NSDictionary *)payload;

- (EWNotification *)newMediaNotification:(EWMedia *)media;
- (void)deleteNewMediaNotificationForActivity:(EWActivity *)activity;
- (void)checkNotifications;

/**
 When new notification received, handle it
 1. Decide weather to alert user
 2. Check if is in the notification queue
 */
- (void)notificationDidClicked:(EWNotification *)note;

//Search
- (NSArray *)notificationsForPerson:(EWPerson *)person;
- (void)findAllNotificationInBackgroundwithCompletion:(ArrayBlock)block;

@end
