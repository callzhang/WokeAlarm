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
    self.importance = 0;
    self.userInfo = [NSDictionary new];
}

+ (EWNotification *)newNotification {
    EWAssertMainThread
    EWNotification *notice = [EWNotification MR_createEntity];
    
    notice.owner = [EWPerson me];
    return notice;
}



+ (EWNotification *)getNotificationByID:(NSString *)notificationID error:(NSError *__autoreleasing *)error{
    EWNotification *notification = (EWNotification *)[EWSync findObjectWithClass:@"EWNotification" withID:notificationID error:error];
    if (!notification) {
        DDLogError(@"%s fail to get notification: %@", __FUNCTION__, (*error).description);
    }
    return notification;
}



- (BOOL)validate{
    BOOL good = YES;
    if (!self.receiver) {
        good = NO;
        DDLogError(@"EWNotification %@ missing receiver", self.serverID);
    }
    if (!self.type) {
        good = NO;
        DDLogError(@"EWNotification %@ missing type", self.serverID);
    }
    if (!self.owner) {
        good = NO;
        DDLogError(@"EWNotification %@ missing owner", self.serverID);
    }
    
    return good;
}

- (EWServerObject *)ownerObject{
    return self.owner;
}
@end
