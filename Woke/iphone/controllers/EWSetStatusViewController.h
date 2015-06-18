//
//  EWSetStatusViewController.h
//  Woke
//
//  Created by Zitao Xiong on 12/17/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWManagedNavigiationItemsViewController.h"

@interface EWSetStatusViewController : EWManagedNavigiationItemsViewController
@property (nonatomic, strong) EWAlarm *alarm;
@end
