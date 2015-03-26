//
//  EWNotification.h
//  Woke
//
//  Created by Lei on 4/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_EWNotification.h"

@class EWPerson;

@interface EWNotification : _EWNotification

@property (nonatomic, retain) NSDictionary *lastLocation;
@property (nonatomic, retain) NSDictionary *userInfo;
/**
 check if store notification is the same state as server
 */
+ (EWNotification *)getNotificationByID:(NSString *)notificationID error:(NSError **)error;
+ (EWNotification *)newNotification;
@end
