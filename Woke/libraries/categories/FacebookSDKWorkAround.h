//
//  FacebookSDKWorkAround.h
//  Woke
//
//  Created by Zitao Xiong on 6/8/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBSDKShareKit.h"
#import "FBSDKGraphRequestConnection.h"

@interface FBSDKGraphRequestConnection(Workaround)
+ (void)startWithGraphPath:(NSString *)graphPath completionHandler:(FBSDKGraphRequestHandler)handlers;
@end
