//
//  FacebookSDKWorkAround.m
//  Woke
//
//  Created by Zitao Xiong on 6/8/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "FacebookSDKWorkAround.h"
#import "FBSDKGraphRequest.h"

@implementation FBSDKGraphRequestConnection


+ (void)startWithGraphPath:(NSString *)graphPath completionHandler:(FBSDKGraphRequestHandler)handlers {
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:nil];
    [request startWithCompletionHandler:handlers];
}

@end