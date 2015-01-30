//
//  EWBaseViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWBaseViewController.h"
#import "EWMainNavigationController.h"

@interface EWBaseViewController ()

@end

@implementation EWBaseViewController
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    // 2. All known destination controllers assigned to properties
    if ([self respondsToSelector:NSSelectorFromString(segue.identifier)]) {
        [self setValue:segue.destinationViewController forKey:segue.identifier];
    }
}

@end
