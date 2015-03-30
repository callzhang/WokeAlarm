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


FBTweakAction(@"Notification", @"Action", @"Check notifications", ^{
    [[EWNotificationManager sharedInstance] checkNotifications];
});

@interface EWNotificationManager()
//@property EWPerson *person;
//@property EWMedia *media;
//@property (nonatomic)  EWNotification *notification;
@end

@implementation EWNotificationManager
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS(EWNotificationManager)


#pragma mark - Handle
- (void)handleNotificatoinFromPush:(NSDictionary *)payload{
    NSString *notificationID = payload[kPushNofiticationID];
    NSError *error;
    EWNotification *notice = [EWNotification getNotificationByID:notificationID error:&error];
    if (!notice) {
        DDLogError(@"Failed to get notice(%@) with error: %@", notificationID, error.localizedDescription);
        return;
    }
    [[EWPerson me] addNotificationsObject:notice];
	
	//save
    [notice saveWithCompletion:^(BOOL success, NSError *error) {
		//broadcast
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNew object:notice userInfo:nil];
	}];
    
    [self notificationDidClicked:notificationID];
}


- (void)notificationDidClicked:(NSString *)notificationID{
    NSError *error;
    EWNotification *notification = [EWNotification getNotificationByID:notificationID error:&error];
    if (!notification) {
        DDLogError(@"Cannot find notification %@ error: %@", notificationID, error.localizedDescription);
        return;
    }
    
    
    //[EWNotificationManager sharedInstance].notification = notification;
    
    if ([notification.type isEqualToString:kNotificationTypeNewMedia]) {
		
        [EWUIUtil showSuccessHUBWithString:@"You got a new voice!"];
        
    } else if ([notification.type isEqualToString:kNotificationTypeFriendRequest]) {
        
        //NSString *personID = notification.sender;
        //EWPerson *person = notification.owner;
        
        NSString *personID = notification.sender;
        
        EWPerson *requester = [[EWPersonManager sharedInstance] getPersonByServerID:personID error:nil];
        
        if (!requester) {
            DDLogError(@"Failed to get person (%@) error: %@", personID, error.localizedDescription);
            return;
        }
        
        if (notification.completed) {
            //show profile view
            EWProfileViewController *controller = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWProfileViewController"];
            controller.person = requester;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
            [[UIWindow mainWindow].rootViewController presentWithBlur:navController withCompletion:NULL];
            
        } else {
            [UIAlertView bk_showAlertViewWithTitle:@"Friendship request" message:[NSString stringWithFormat:@"%@ wants to be your friend.", requester.name] cancelButtonTitle:@"Don't accept" otherButtonTitles:@[@"Accept", @"Profile"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                switch (buttonIndex) {
                    case 0: //Cancel
                        
                        break;
                        
                    case 1:{ //accepted
                        [[EWPerson me] addFriendsObject:requester];
                        [requester addFriendsObject:[EWPerson me]];
                        [[EWPersonManager shared] acceptFriend:requester completion:^(EWFriendshipStatus status, NSError *error) {
                            if (status == EWFriendshipStatusFriended) {
                                [EWUIUtil showSuccessHUBWithString:@"Accepted"];
                            }
                        }];
                        break;
                    }
                    case 2:{ //profile
                        EWProfileViewController *controller = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWProfileViewController"];
                        controller.person = requester;
                        EWBaseNavigationController *navController = [[EWBaseNavigationController alloc] initWithRootViewController:controller];
                        [[UIWindow mainWindow].rootViewController presentWithBlur:navController withCompletion:NULL];
                        break;
                    }
                    default:
                        break;
                }
            }];
        }
        
    } else if ([notification.type isEqualToString:kNotificationTypeFriendAccepted]) {
        
        NSString *personID = notification.sender;
        EWPerson *person = [[EWPersonManager sharedInstance] getPersonByServerID:personID error:&error];
        if (!person) {
            DDLogError(@"Failed to get person (%@) error: %@", personID, error.localizedDescription);
            return;
        }
        
        //alert
        if (notification.completed) {
            EWProfileViewController *controller = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWProfileViewController"];
			controller.person = person;
			
            [[UIApplication sharedApplication].delegate.window.rootViewController presentWithBlur:controller withCompletion:NULL];
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friend accepted"
                                                            message:[NSString stringWithFormat:@"%@ has accepted your friend request. View profile?", person.name]
                                                           delegate:[EWNotificationManager sharedInstance]
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
            alert.tag = kFriendAcceptedAlert;
            [alert show];
            
            [UIAlertView bk_showAlertViewWithTitle:@"Friendship accepted" message:[NSString stringWithFormat:@"%@ has accepted your friend request. View profile?", person.name] cancelButtonTitle:@"No" otherButtonTitles:@[@"YES"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex == 0) {
                    return;
                }
                EWProfileViewController *controller = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWProfileViewController"];
                controller.person = person;
                EWBaseNavigationController *navController = [[EWBaseNavigationController alloc] initWithRootViewController:controller];
                [[UIWindow mainWindow].rootViewController presentWithBlur:navController withCompletion:NULL];
            }];
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
        
    }else if ([notification.type isEqualToString:kNotificationTypeNewUser]) {
        EWProfileViewController *controller = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWProfileViewController"];
        EWPerson *friend = [[EWPersonManager sharedInstance] getPersonByServerID:notification.sender error:nil];
        controller.person = friend;
        EWBaseNavigationController *navController = [[EWBaseNavigationController alloc] initWithRootViewController:controller];
        [[UIWindow mainWindow].rootViewController presentWithBlur:navController withCompletion:NULL];
    }
    else{
        NSString *str = [NSString stringWithFormat:@"unknown type of notification: %@", notification.type];
        DDLogError(str);
        EWAlert(str);
    }
    
    [self setCompletionForNotification:notification];
}


- (void)setCompletionForNotification:(EWNotification *)notice{
	//archieve
	if (!notice.completed) {
        notice.completed = [NSDate date];
        [notice save];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCompleted object:notice];
	}

}

- (void)checkNotifications{
	EWActivity *currentActivity = [EWPerson myCurrentAlarmActivity];
	[mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        //remove past new media notifications
		EWActivity *localCurrentActivity = [currentActivity MR_inContext:localContext];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@ AND %K != %@", EWNotificationAttributes.type, kNotificationTypeNewMedia, @"userInfo.activity", localCurrentActivity.serverID];
		NSArray *notificationForPastActivities = [EWNotification MR_findAllWithPredicate:predicate inContext:localContext];
//        NSArray *pastMediaNotifications = [[EWPerson meInContext:localContext].notifications.allObjects bk_select:^BOOL(EWNotification *note) {
//            if (note.type == kNotificationTypeNewMedia && ![note.userInfo[@"activity"] isEqualToString:localCurrentActivity.serverID]) {
//                return YES;
//            }
//            return NO;
//        }];
		for (EWNotification *note in notificationForPastActivities) {
			EWActivity *activity = (EWActivity *)[EWSync findObjectWithClass:NSStringFromClass([EWActivity class]) withID:note.userInfo[@"activity"] inContext:localContext error:nil];
			DDLogInfo(@"Removed redundant notification (%@) on %@", note.serverID, activity.time);
			[note remove];
		}
		
		//download related person
		NSMutableSet *senderIDs = [[[EWPerson meInContext:localContext].notifications valueForKey:EWNotificationAttributes.sender] mutableCopy];
		PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([EWPerson class]).serverClass];
		[query whereKeyExists:EWPersonAttributes.profilePic];
		[query fromLocalDatastore];
		NSArray *localPersonIDs = [[query findObjects:nil] valueForKey:kParseObjectID];
		[senderIDs minusSet:[NSSet setWithArray:localPersonIDs]];
		PFQuery *personQuery = [PFQuery queryWithClassName:NSStringFromClass([EWPerson class])];
		if (senderIDs.count) {
			[personQuery whereKey:kParseObjectID containedIn:senderIDs.allObjects];
			NSArray *senders = [EWSync findObjectFromServerWithQuery:personQuery inContext:localContext error:nil];
			DDLogInfo(@"Found senders from checking notification: %@", [senders valueForKey:EWPersonAttributes.firstName]);
		}
	} completion:^(BOOL contextDidSave, NSError *error) {
		DDLogVerbose(@"Finished checking notifications %@", error.localizedDescription);
        [[EWSync sharedInstance] uploadToServer];
	}];
	
}

- (void)deleteNewMediaNotificationForActivity:(EWActivity *)activity{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@", EWNotificationAttributes.type, kNotificationTypeNewMedia, @"userInfo.activity", activity.serverID];
	NSArray *notificationForPastActivities = [EWNotification MR_findAllWithPredicate:predicate];
	
	for (EWNotification *note in notificationForPastActivities) {
		DDLogInfo(@"Removed redundant notification (%@) for activity on %@", note.serverID, activity.time);
		[note remove];
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
	note.receiver = [EWPerson me].serverID;
	EWActivity *activity = [EWPerson myCurrentAlarmActivity];
	if (!activity.serverID) {
		[activity updateToServerWithCompletion:^(EWServerObject *MO_on_main_thread, NSError *error) {
			if (error || !MO_on_main_thread.serverID) {
				DDLogError(@"Failed to save notification (%@) with error %@", note.serverID, error);
			}else {
				note.userInfo = @{@"medias": @[media.serverID], @"activity": MO_on_main_thread.serverID};
				[note save];
			}
		}];
	}else{
		note.userInfo = @{@"medias": @[media.serverID], @"activity": activity.serverID};
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
	[query whereKey:EWNotificationRelationships.owner equalTo:[PFUser objectWithoutDataWithObjectId:[PFUser currentUser].objectId]];//send PFUser directly maybe cause error
    [EWSync findObjectsFromServerInBackgroundWithQuery:query completion:^(NSArray *notifications, NSError *error) {
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

@end
