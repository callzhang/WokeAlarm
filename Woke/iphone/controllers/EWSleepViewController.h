//
//  EWSleepViewController.h
//  Woke
//
//  Created by Zitao Xiong on 22/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWSleepViewModel.h"
#import "EWBaseViewController.h"

@interface EWSleepViewController : EWBaseViewController
@property (nonatomic, strong) EWSleepViewModel *sleepViewModel;
@end
