//
//  EWNotificationManager.m
//  Woke
//
//  Created by Lei on 4/20/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWMedia.h"
#import "EWMediaManager.h"
#import "EWProfileViewController.h"
#import "EWWakeUpManager.h"
#import "EWServer.h"
#import "EWCachedInfoManager.h"
#import "UIViewController+Blur.h"
#import "UIView+Extend.h"
#import "EWUIUtil.h"
#import "UIAlertView+BlocksKit.h"
#import "NSArray+BlocksKit.h"
#import "EWActivity.h"
#import "NSDictionary+KeyPathAccess.h"

#define kNextTaskHasMediaAlert      1011
#define kFriendRequestAlert         1012
#define kFriendAcceptedAlert        1013
#define kTimerEventAlert            1014
#define kSystemNoticeAlert          1015

#define nNotificationToDisplay      9


@interface EWNotificationManager()
@property EWPerson *person;
@property EWMedia *media;
@property (nonatomic)  EWNotification *notification;
@end

@implementation EWNotificationManager
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS(EWNotificationManager)


#pragma mark - Handle
- (void)handleNotificatoinFromPush:(NSDictionary *)payload{
    NSString *notificationID = payload[kPushNofiticationID];
    EWNotification *notice = [EWNotification getNotificationByID:notificationID];
    [[EWPerson me] addNotificationsObject:notice];
	
	//save
    [notice saveWithCompletion:^(BOOL success, NSError *error) {
		//broadcast
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNew object:notice userInfo:nil];
	}];
}


- (void)handleNotification:(NSString *)notificationID{
    EWNotification *notification = [EWNotification getNotificationByID:notificationID];
    if (!notification) {
        DDLogError(@"@@@ Cannot find notification %@", notificationID);
        return;
    }
    
    
    [EWNotificationManager sharedInstance].notification = notification;
    
    if ([notification.type isEqualToString:kNotificationTypeNewMedia]) {
		
		[UIAlertView bk_showAlertViewWithTitle:@"New Voice" message:@"You've got a new voice for your next morning!" cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
			//do nothing
			DDLogVerbose(@"New voice alert view clicked");
		}];
        
    } else if ([notification.type isEqualToString:kNotificationTypeFriendRequest]) {
        
        //NSString *personID = notification.sender;
        //EWPerson *person = notification.owner;
        
        NSString *personID = notification.sender;
        EWPerson *person = [[EWPersonManager sharedInstance] getPersonByServerID:personID];
        [EWNotificationManager sharedInstance].person = person;
        
        //alert
        UIAlertView *alert;
        alert = [[UIAlertView alloc] initWithTitle:@"Friendship request"
                                           message:[NSString stringWithFormat:@"%@ wants to be your friend.", person.name]
                                          delegate:[EWNotificationManager sharedInstance]
                                 cancelButtonTitle:@"Don't accept"
                                 otherButtonTitles:@"Accept", @"Profile", nil];
        alert.tag = kFriendRequestAlert;
        [alert show];
        
    } else if ([notification.type isEqualToString:kNotificationTypeFriendAccepted]) {
        
        NSString *personID = notification.sender;
        EWPerson *person = [[EWPersonManager sharedInstance] getPersonByServerID:personID];
        //EWPerson *person = notification.owner;
        [EWNotificationManager sharedInstance].person = person;
        
        //update cache
        //[EWCachedInfoManager updateCacheWithFriendsAdded:@[person.serverID]];
        
        //alert
        if (notification.completed) {
            EWProfileViewController *controller = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWProfileViewController"];
			controller.person = person;
			
            [[UIApplication sharedApplication].delegate.window.rootViewController presentWithBlur:controller withCompletion:^{
                //
            }];
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friend accepted"
                                                            message:[NSString stringWithFormat:@"%@ has accepted your friend request. View profile?", person.name]
                                                           delegate:[EWNotificationManager sharedInstance]
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
            alert.tag = kFriendAcceptedAlert;
            [alert show];
        }
        
        
        
    } else if ([notification.type isEqualToString:kNotificationTypeSystemNotice]) {
        //UserInfo
        //->Title
        //->Content
        //->Link
        NSString *title = notification.userInfo[@"title"];
        NSString *body = notification.userInfo[@"content"];
        //NSString *link = notification.userInfo[@"link"];
        [[[UIAlertView alloc] initWithTitle:title
                                    message:[NSString stringWithFormat:@"%@\n", body]
                                   delegate:[EWNotificationManager sharedInstance]
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: @"More", nil] show];
        
    }else{
        
        DDLogError(@"@@@ unknown type of notification");
    }
}

#pragma mark - New
- (EWNotification *)newMediaNotification:(EWMedia *)media{
	//make only unique media notification per day
    if ([EWSession sharedSession].wakeupStatus != EWWakeUpStatusWoke) {
        DDLogInfo(@"Received media on status (%ld) but not to react to it.", [EWSession sharedSession].wakeupStatus);
    }
	EWNotification *notification= [[EWPerson myNotifications] bk_match:^BOOL(EWNotification *notif) {
		if ([notif.type isEqualToString:kNotificationTypeNewMedia]) {
			//new media go with the activity
			NSString *activityID = [EWPerson myCurrentAlarmActivity].serverID;
			if ([notif.userInfo[@"activity"] isEqualToString:activityID]) {
                DDLogVerbose(@"Found media notification for activity %@", activityID);
				return YES;
			}
		}
		return NO;
	}];
	
	if (notification) {
        DDLogVerbose(@"Added media %@ to exisiting media notification %@", media.serverID, notification.serverID);
		notification.userInfo = [notification.userInfo addValue:media.objectId toImmutableKeyPath:@[@"medias"]];
		[notification save];
		return notification;
	}
	
	EWNotification *note = [EWNotification newNotification];
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


#pragma mark - Search
- (NSArray *)notificationsForPerson:(EWPerson *)person{
    NSArray *notifications = person.notifications.allObjects;
	
    NSSortDescriptor *sortCompelete = [NSSortDescriptor sortDescriptorWithKey:EWNotificationAttributes.completed ascending:YES];
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.createdAt ascending:NO];
    NSSortDescriptor *sortImportance = [NSSortDescriptor sortDescriptorWithKey:EWNotificationAttributes.importance ascending:NO];
    
    notifications = [notifications sortedArrayUsingDescriptors:@[sortImportance, sortDate, sortCompelete]];
    
    return notifications;
}

- (void)findAllNotificationInBackgroundwithCompletion:(ArrayBlock)block{

    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([EWNotification class])];
    if ([EWPerson me].notifications.count > 0) {
		NSSet *existingNotes = [[EWPerson me].notifications valueForKey:kParseObjectID];
        [query whereKey:kParseObjectID notContainedIn:existingNotes.allObjects];
    }
	[query whereKey:EWNotificationRelationships.owner equalTo:[PFUser objectWithoutDataWithObjectId:[PFUser currentUser].objectId]];
    [EWSync findParseObjectInBackgroundWithQuery:query completion:^(NSArray *notifications, NSError *error) {
        for (EWNotification *notification in notifications) {
				NSAssert(notification.ownerObject == [EWPerson me], @"owner missing: %@", notification.ownerObject.serverID);
				DDLogVerbose(@"Found new notification %@(%@)", notification.type, notification.objectId);
        }
        if (block) {
            NSArray *notes = [EWPerson myNotifications];
            block(notes, error);
        }
    }];
}


#pragma mark - Handle alert
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView.tag == kFriendRequestAlert) {
        
        switch (buttonIndex) {
            case 0: //Cancel
                
                break;
                
            case 1:{ //accepted
                [[EWPerson me] addFriendsObject:self.person];
                [self.person addFriendsObject:[EWPerson me]];
                [[EWPersonManager shared] acceptFriend:_person completion:^(EWFriendshipStatus status, NSError *error) {
                    if (status == EWFriendshipStatusFriended) {
                        [EWUIUtil showSuccessHUBWithString:@"Accepted"];
                    }
                }];
                break;
            }
            case 2:{ //profile
				EWProfileViewController *controller = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWProfileViewController"];
				controller.person = _person;
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                [[UIWindow mainWindow].rootViewController presentWithBlur:navController withCompletion:^{
                    //
                }];
                break;
            }
            default:
                break;
        }
        
    }else if (alertView.tag == kFriendAcceptedAlert){
        
        switch (buttonIndex) {
            case 0:
                //Do not view profile, do nothing
                break;
            
            case 1:{//view profile
				EWProfileViewController *controller = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWProfileViewController"];
				controller.person = _person;
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
                [[UIWindow mainWindow].rootViewController presentWithBlur:navController withCompletion:^{
                    //
                }];
            }
                break;
                
            default:
                break;
        }
        
    }else{
        //
    }
    
    
    [self finishedNotification:self.notification];
    
}

- (void)finishedNotification:(EWNotification *)notice{
    //archieve
    if (!notice.completed) {
        notice.completed = [NSDate date];
    }
    [notice save];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCompleted object:notice];
    
    self.notification = nil;
    self.person = nil;
}

@end
