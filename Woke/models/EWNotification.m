//
//  EWNotification.m
//  Woke
//
//  Created by Lei on 4/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWNotification.h"
#import "EWPerson.h"
#import "EWMedia.h"
#import "EWActivity.h"
#import "NSArray+BlocksKit.h"

@implementation EWNotification
@dynamic userInfo;
@dynamic lastLocation;
@dynamic importance;

+ (EWNotification *)newNotification {
    NSParameterAssert([NSThread isMainThread]);
    EWNotification *notice = [EWNotification MR_createEntity];
    notice.updatedAt = [NSDate date];
    notice.owner = [EWPerson me];
    notice.importance = 0;
    return notice;
}

+ (EWNotification *)newMediaNotification:(EWMedia *)media{
    EWNotification *notification= [[EWPerson myNotifications] bk_match:^BOOL(EWNotification *notif) {
        if ([notif.type isEqualToString:kNotificationTypeNewMedia]) {
            if (notif.userInfo[@"activity"] == [EWPerson myCurrentAlarmActivity]) {
                return YES;
            }
        }
        return NO;
    }];
    
    if (notification) {
        return notification;
    }

    EWNotification *note = [self newNotification];
    note.type = kNotificationTypeNewMedia;
    note.userInfo = @{@"media": media.objectId};
    note.sender = media.author.objectId;
    note.receiver = [EWPerson me].objectId;
    [EWSync save];
    
    return note;
}

- (void)remove {
    DDLogInfo(@"Notification of type %@ deleted", self.type);
    [self MR_deleteEntity];
    [EWSync save];
}

- (BOOL)validate{
    BOOL good = YES;
    if (!self.receiver) {
        good = NO;
        DDLogError(@"EWNotification missing receiver");
    }
    if (!self.type) {
        good = NO;
        DDLogError(@"EWNotification missing type");
    }
    if (!self.owner) {
        good = NO;
        DDLogError(@"EWNotification missing owner");
    }
    
    return good;
}
@end
