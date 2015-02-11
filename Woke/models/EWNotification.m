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
#import "NSDictionary+KeyPathAccess.h"

@implementation EWNotification
@dynamic userInfo;
@dynamic lastLocation;
@dynamic importance;

- (void)awakeFromInsert{
    [super awakeFromInsert];
    self.updatedAt = [NSDate date];
    self.importance = 0;
}

+ (EWNotification *)newNotification {
    EWAssertMainThread
    EWNotification *notice = [EWNotification MR_createEntity];
    
    notice.owner = [EWPerson me];
    return notice;
}



+ (EWNotification *)getNotificationByID:(NSString *)notificationID{
    NSError *error;
    EWNotification *notification = (EWNotification *)[EWSync findObjectWithClass:@"EWNotification" withID:notificationID error:&error];
    if (!notification) {
        DDLogError(@"%s fail to get notification: %@", __FUNCTION__, error.description);
    }
    return notification;
}


+ (EWNotification *)newMediaNotification:(EWMedia *)media{
	//make only unique media notification per day
    EWNotification *notification= [[EWPerson myNotifications] bk_match:^BOOL(EWNotification *notif) {
        if ([notif.type isEqualToString:kNotificationTypeNewMedia]) {
            if (notif.userInfo[@"activity"] == [EWPerson myCurrentAlarmActivity].objectId) {
                return YES;
            }
        }
        return NO;
    }];
    
    if (notification) {
        notification.userInfo = [notification.userInfo addValue:media.objectId toImmutableKeyPath:@[@"medias"]];
        [notification save];
        return notification;
    }

    EWNotification *note = [self newNotification];
    note.type = kNotificationTypeNewMedia;
    note.sender = media.author.objectId;
    note.receiver = [EWPerson me].objectId;
    EWActivity *activity = [EWPerson myCurrentAlarmActivity];
    if (!activity.objectId) {
        [activity updateToServerWithCompletion:^(EWServerObject *MO_on_main_thread, NSError *error) {
            if (error) {
                DDLogError(@"Failed to save notification (%@) with error %@", note.serverID, error);
            }else {
                note.userInfo = @{@"medias": @[media.serverID], @"activity": MO_on_main_thread.serverID};
                [note save];
            }
        }];
    }else{
        note.userInfo = @{@"medias": @[media.objectId], @"activity": activity.objectId};
        [note save];
    }
    return note;
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

- (EWServerObject *)ownerObject{
    return self.owner;
}
@end
