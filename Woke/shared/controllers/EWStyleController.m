//
//  EWStyleController.m
//  Woke
//
//  Created by Zitao Xiong on 12/7/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWStyleController.h"
#import "EWFontHelper.h"

@implementation EWStyleController

+ (void)applySystemStyle {
    NSDictionary *navbarTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName:EWRegularFontWithSize(20.0)};
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    
    [[UIView appearanceWhenContainedIn:[UIAlertController class], nil] setTintColor:[UIColor colorWithRed:0 green:122/255.0 blue:1.0 alpha:1.0]];

    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName: EWRegularFontWithSize(20), NSForegroundColorAttributeName: [UIColor whiteColor]}];
}
@end
