//
//  EWErrorManager.h
//  Woke
//
//  Created by Zitao Xiong on 16/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kWokeDomain     @"WokeAlarm"
#define kEWNoInternetReachabilityErrorCode      101
#define kEWInvalidObjectErrorCode               102

extern NSString * const EWErrorDomain;
extern NSString * const EWErrorInfoDescriptionKey;

@interface EWErrorManager : NSObject
+ (void)handleError:(NSError *)error;
+ (NSError *)noInternetConnectError;
+ (NSError *)invalidObjectError:(id)obj;
@end
