//
//  EWServer.m
//  EarlyWorm
//
//  Translate client requests to server custom code, providing a set of tailored APIs to client coding environment.
//
//  Created by Lee on 2/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWServer.h"

//model
#import "EWStartUpSequence.h"
#import "EWPersonManager.h"
#import "EWMedia.h"
#import "EWMediaManager.h"
#import "EWNotification.h"
#import "EWNotificationManager.h"
#import "EWWakeUpManager.h"

//view
//TODO: #import "EWWakeUpViewController.h"
#import "EWAVManager.h"
//#import "UIAlertView+.h"
#import "EWSleepViewController.h"

//Tool
#import "EWUIUtil.h"
#import "EWAlarmManager.h"
#import "FBRequestConnection.h"
#import "FBSession.h"

@implementation EWServer

+ (EWServer *)sharedInstance{
    static EWServer *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EWServer alloc] init];
    });
    return manager;
}

#pragma mark - Handle Push Notification
+ (void)handlePushNotification:(NSDictionary *)push{
	NSString *type = push[kPushType];
					  
    if ([type isEqualToString:kPushTypeMedia]) {
		[[EWMediaManager sharedInstance] handlePushMedia:push];
		
	}
	else if([type isEqualToString:kPushTypeAlarmTimer]){
		// ============== Alarm Timer ================
		[[EWWakeUpManager sharedInstance] startToWakeUp:push];
		
	}
	else if ([type isEqualToString:kPushTypeNotification]){
		NSString *notificationID = push[kPushNofiticationID];
		[EWNotificationManager handleNotification:notificationID];
	}
    else if ([type isEqualToString:kPushTypeBroadcast]){
        NSString *message = push[@"alert"];
        EWAlert(message);
    }
	else{
		// Other push type not supported
		NSString *str = [NSString stringWithFormat:@"Unknown push type received: %@", push];
		DDLogError(@"Received unknown type of push msg: %@", str);
#ifdef DEBUG
		EWAlert(str);
#endif
	}
}


#pragma mark - Handle Local Notification
+ (void)handleLocalNotification:(UILocalNotification *)notification{
    NSString *type = notification.userInfo[kLocalNotificationTypeKey];
    DDLogVerbose(@"Received local notification: %@", type);
    
    if ([type isEqualToString:kLocalNotificationTypeAlarmTimer]) {
        [[EWWakeUpManager sharedInstance] startToWakeUp:notification.userInfo];
		
    }else if([type isEqualToString:kLocalNotificationTypeReactivate]){
        DDLogVerbose(@"==================> Reactivated Woke <======================");
        EWAlert(@"You brought me back!");
		
    }else if ([type isEqualToString:kLocalNotificationTypeSleepTimer]){
        DDLogVerbose(@"=== Received Sleep timer local notification, broadcasting sleep event, and enter sleep mode... \n%@", notification);
        
        [[EWWakeUpManager sharedInstance] sleep:notification];
    }
    else{
        DDLogWarn(@"Unexpected Local Notification Type. Detail: %@", notification);
    }

}



#pragma mark - Send Voice tone
+ (void)pushVoice:(EWMedia *)media toUser:(EWPerson *)person withCompletion:(void (^)(BOOL success))block{
    
    //save
    [EWSync saveWithCompletion:^{
        //update Person->medias relation
        [self updateRelation:@"medias" for:person.parseObject withObject:media.parseObject withOperation:@"add" completion:NULL];
        
        //set ACL
        PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
        if ([[EWPerson me].objectId isEqualToString:WokeUserID]) {
            //if WOKE, set public
            [acl setPublicReadAccess:YES];
            [acl setPublicWriteAccess:YES];
        }else{
            
            [acl setReadAccess:YES forUserId:person.objectId];
            [acl setWriteAccess:YES forUserId:person.objectId];
        }
        
        PFObject *object = media.parseObject;
        [object setACL:acl];
        [object saveInBackground];
        
        NSDictionary *pushMessage = @{@"badge": @"Increment",
                                      @"alert": @"Someone has sent you an voice greeting",
                                      @"content-available": @1,
                                      kPushType: kPushTypeMedia,
                                      kPushMediaType: kPushMediaTypeVoice,
                                      kPushPersonID: [EWPerson me].objectId,
                                      kPushMediaID: media.objectId,
                                      @"sound": @"media.caf",
                                      @"alert": @"Someone has sent you an voice greeting"
                                      };
        
        
        //push
        [EWServer parsePush:pushMessage toUsers:@[person] completion:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                DDLogError(@"Send push message about media %@ failed. Reason:%@", media.objectId, error.description);
            }
            if (block) {
                block(succeeded);
            }
        }];
        
        //save
        [EWSync save];
    }];
    
    
    
}



+ (void)broadcastMessage:msg onSuccess:(VoidBlock)block onFailure:(VoidBlock)failureBlock{
    
    NSDictionary *payload = @{@"alert": msg,
                              @"sound": @"new.caf",
                              kPushType: kPushTypeBroadcast};
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKeyExists:@"username"];
    PFPush *push = [PFPush new];
    [push setQuery:pushQuery];
    [push setData:payload];
    block = block?:NULL;
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded && block) {
            block();
        }else if (failureBlock){
            DDLogError(@"Failed to broadcast push message: %@", error.description);
            failureBlock();
        }
    }];
}


#pragma mark - Parse Push
+ (void)parsePush:(NSDictionary *)pushPayload toUsers:(NSArray *)users completion:(PFBooleanResultBlock)block{
    
    NSArray *userIDs = [users valueForKey:kUsername];
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:kUsername containedIn:userIDs];
    PFPush *push = [PFPush new];
    [push setQuery:pushQuery];
    [push setData:pushPayload];
    block = block?:NULL;
    //[push sendPushInBackgroundWithBlock:block];
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        block(succeeded, error);
    }];
}


#pragma mark - Notification
+ (void)requestNotificationPermissions{
    //push
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeNone;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
#if !TARGET_IPHONE_SIMULATOR
    [[UIApplication sharedApplication] registerForRemoteNotifications];

#endif
}

+ (void)registerPushNotificationWithToken:(NSData *)deviceToken{
    
    //Parse: Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}


+(void)searchForFriendsOnServer
{
    PFQuery *q = [PFQuery queryWithClassName:@"User"];
    
    //[q whereKey:@"email" containedIn:[EWUtil readContactsEmailsFromAddressBooks]];
    
    [EWSync findServerObjectInBackgroundWithQuery:q completion:^(NSArray *objects, NSError *error) {
        if (!error) {
            
            // push  notification;
            
            
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    
}

+(void)publishOpenGraphUsingAPICallsWithObjectId:(NSString *)objectId andUrlString:(NSString *)url {
    
    // We will post a story on behalf of the user
    // These are the permissions we need:
    NSArray *permissionsNeeded = @[@"publish_actions"];
    
    // Request the permissions the user currently has
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error){
                                  NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
                                  NSLog(@"current permissions %@", currentPermissions);
                                  NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
                                  
                                  // Check if all the permissions we need are present in the user's current permissions
                                  // If they are not present add them to the permissions to be requested
                                  for (NSString *permission in permissionsNeeded){
                                      if (![currentPermissions objectForKey:permission]){
                                          [requestPermissions addObject:permission];
                                      }
                                  }
                                  
                                  // If we have permissions to request
                                  if ([requestPermissions count] > 0){
                                      // Ask for the missing permissions
                                      [FBSession.activeSession requestNewPublishPermissions:requestPermissions
                                                                            defaultAudience:FBSessionDefaultAudienceFriends
                                                                          completionHandler:^(FBSession *session, NSError *err) {
                                                                              if (!err) {
                                                                                  // Permission granted
                                                                                  NSLog(@"new permissions %@", [FBSession.activeSession permissions]);
                                                                                  // We can request the user information
                                                          [EWServer makeRequestToPostStoryWithId:objectId andUrlString:url];
                                                        //upload a graph and form a OG story
                                                                                  
                                                                              } else {
                                                                                  // An error occurred, we need to handle the error
                                                                                  // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                                                                  NSLog(@"error %@", err.description);
                                                                              }
                                                                          }];
                                  } else {
                                      // Permissions are present
                                      // We can request the user information
                                      
                                      [EWServer makeRequestToPostStoryWithId:objectId andUrlString:url];
                                       //upload a graph and form a OG story
                                  }
                                  
                              } else {
                                  // An error occurred, we need to handle the error
                                  // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                  NSLog(@"error %@", error.description);
                              }
                          }];

    
    
}







+(void)updatingStatusInFacebook:(NSString *)status
{
    // NOTE: pre-filling fields associated with Facebook posts,
    // unless the user manually generated the content earlier in the workflow of your app,
    // can be against the Platform policies: https://developers.facebook.com/policy
    
    [FBRequestConnection startForPostStatusUpdate:status
                                completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                    if (!error) {
                                        // Status update posted successfully to Facebook
                                        NSLog(@"result: %@", result);
                                        
                                    } else {
                                        // An error occurred, we need to handle the error
                                        // See: https://developers.facebook.com/docs/ios/errors
                                        NSLog(@"%@", error.description);
                                    }
                                }];
}

+(void)uploadOGStoryWithPhoto:(UIImage *)image

{
    
//    [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//        //__block NSString *alertText;
//        //__block NSString *alertTitle;
//        __block NSString *urlString ;
//        if(!error) {
//            
//            NSArray *_image = @[@{@"url": [result objectForKey:@"uri"], @"user_generated" : @"true" }];
//            
//            urlString = [result objectForKey:@"uri"];
//   
//            // Package image inside a dictionary, inside an array like we'll need it for the object
//            
//            
//            // Create an object
//            NSMutableDictionary<FBOpenGraphObject> *place = [FBGraphObject openGraphObjectForPost];
//            
//            // specify that this Open Graph object will be posted to Facebook
//            place.provisionedForPost = YES;
//            
//            // Add the standard object properties
//            place[@"og"] = @{ @"title":@"Woke Now", @"type":@"woke_alarm:people", @"description":@"Woke up", @"image":_image };
//            
//            // Add the properties restaurant inherits from place
//            place[@"place"] = @{ @"location" : @{ @"longitude": @"-58.381667", @"latitude":@"-34.603333"} };
//            
//            // Add the properties particular to the type restaurant.restaurant
//            place[@"restaurant"] = @{@"category": @[@"Mexican"],
//                                          @"contact_info": @{@"street_address": @"123 Some st",
//                                                             @"locality": @"Menlo Park",
//                                                             @"region": @"CA",
//                                                             @"phone_number": @"555-555-555",
//                                                             @"website": @"http://www.example.com"}};
//            
//            // Make the Graph API request to post the object
//            FBRequest *request = [FBRequest requestForPostWithGraphPath:@"me/objects/woke_alarm:people"
//                                                            graphObject:@{@"object":place}];
//            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//                if (!error) {
//                    // Success! Include your code to handle the results here
//                    NSLog(@"result: %@", result);
//                    NSString *  _objectID = [result objectForKey:@"id"];
//                    [EWServer publishOpenGraphUsingAPICallsWithObjectId:_objectID andUrlString:urlString];
//                    
//                } else {
//                    // An error occurred, we need to handle the error
//                    // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
//                    NSLog(@"error %@", error.description);
//                }
//            }];
//        } else {
//            // An error occurred, we need to handle the error
//            // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
//            NSLog(@"error %@", error.description);
//        }
//    }];

}

+(void)makeRequestToPostStoryWithId:(NSString *)objectId andUrlString:(NSString *)url
{
    if(!objectId){
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Please tap the \"Post an object\" button first to create an object, then you can click on this button to like it."
                                   delegate:self
                          cancelButtonTitle:@"OK!"
                          otherButtonTitles:nil] show];
    } else {
        // Create a like action
        id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
        
        // Link that like action to the restaurant object that we have created
//        [action setObject:objectId forKey:@"object"];
        action[@"people"] = objectId;
        
        // Post the action to Facebook
//        [FBRequestConnection startForPostWithGraphPath:@"me/woke_alarm:woke"
//                                           graphObject:action
//                                     completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//                                         __block NSString *alertText;
//                                         __block NSString *alertTitle;
//                                         if (!error) {
//                                             // Success, the restaurant has been liked
//                                             NSLog(@"Posted OG action, id: %@", [result objectForKey:@"id"]);
//                                             alertText = [NSString stringWithFormat:@"Posted OG action, id: %@", [result objectForKey:@"id"]];
//                                             alertTitle = @"Success";
//                                             [[[UIAlertView alloc] initWithTitle:alertTitle
//                                                                         message:alertText
//                                                                        delegate:self
//                                                               cancelButtonTitle:@"OK!"
//                                                               otherButtonTitles:nil] show];
//                                         } else {
//                                             // An error occurred, we need to handle the error
//                                             // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
//                                             NSLog(@"error %@", error.description);
//                                         }
//                                     }];
        
    }
    
   
 }

#pragma mark - Util
+ (void)updateRelation:(NSString *)relation for:(PFObject *)target withObject:(PFObject *)related withOperation:(NSString *)operation completion:(ErrorBlock)block{
    NSDictionary *dic = @{@"target": target, @"related": related, @"relation": relation, @"operation": operation};
    
    [PFCloud callFunctionInBackground:@"updateRelation" withParameters:dic block:^(id object, NSError *error) {
        if (!object) {
            DDLogError(@"Failed to update relation: %@ with error:%@", dic, error.description);
        }else{
            DDLogVerbose(@"Updated relation: %@(%@) -> %@(%@)", target.parseClassName, target.objectId, relation, related.objectId);
        }
    }];
}

@end
