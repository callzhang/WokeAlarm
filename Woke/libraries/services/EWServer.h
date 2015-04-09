//
//  EWServer.h
//  EarlyWorm
//
//  Created by Lee on 2/21/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"

@interface EWServer : NSObject
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWServer)

#pragma mark - Handle Push Notification
+ (void)handlePushNotification:(NSDictionary *)payload;

#pragma mark - Handle Local Notification
+ (void)handleLocalNotification:(NSDictionary *)userInfo;


/**
 Send push notification for media
 @params mediaId: mediaId
 @params users: array of EWPerson
 @params taskId: taskId
 */
+ (void)pushVoice:(EWMedia *)media toUser:(EWPerson *)person withCompletion:(BoolErrorBlock)block;

#pragma mark - Push methods
+ (void)broadcastMessage:(NSString *)msg onSuccess:(VoidBlock)block onFailure:(VoidBlock)failureBlock;


/**
 Async method to call AWS publish with block handler
 @param pushDic
        the push payload
 @param users
        the EWPerson array
 @param successBlock
        block called when success
 @param failureBlock
        Blcok called when failure
 
 */
//+ (void)AWSPush:(NSDictionary *)pushDic toUsers:(NSArray *)users onSuccess:(void (^)(SNSPublishResponse *response))successBlock onFailure:(void (^)(NSException *exception))failureBlock;


/**
 Async method to call AWS publish with block handler
 @param pushDic
 the push payload
 @param users
 the EWPerson array
 @param successBlock
 block called when success
 @param failureBlock
 Blcok called when failure
 
 */
+ (void)parsePush:(NSDictionary *)pushPayload toUsers:(NSArray *)users completion:(BoolErrorBlock)block;


#pragma mark - Push notification
/**
 Initiate the Push Notification registration to APNS
 */
- (void)requestNotificationPermissions;
/**
 Handle the returned token for registered device. Register the push service to 3rd party server.
 */
- (void)registerPushNotificationWithToken:(NSData *)deviceToken;


//+ (void)searchForFriendsOnServer;

//+(void)publishOpenGraphUsingAPICallsWithObjectId:(NSString *)objectId andUrlString:(NSString *)url;

//+(void)publishOpenGraphUsingShareDialog;// un wirte

//+(void)makeRequestToPostStory;

+(void)updatingStatusInFacebook:(NSString *)status;

+(void)uploadOGStoryWithPhoto:(UIImage *)image;// use this to update a OG story

+(void)makeRequestToPostStoryWithId:(NSString *)objectId andUrlString:(NSString *)url;

#pragma mark - Util
+ (void)updateRelation:(NSString *)relation for:(PFObject *)target withObject:(PFObject *)related withOperation:(NSString *)operation completion:(ErrorBlock)block;

#pragma mark - REST
+ (NSString *) uploadImageToParseREST:(UIImage *)uploadImage;
+ (void)deleteFileFromParseRESTwithURL:(NSURL *)url;
@end
