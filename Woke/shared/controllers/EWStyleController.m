//
//  EWStyleController.m
//  Woke
//
//  Created by Zitao Xiong on 12/7/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWStyleController.h"

@implementation EWStyleController

+ (void)applySystemStyle {
    NSDictionary *navbarTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName:[UIFont fontWithName:@"Lato-Regular" size:20.0]};
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    
}
@end
