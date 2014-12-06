//
//  EWBaseNavigationController.m
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWBaseNavigationController.h"
#import "EWActivityManager.h"
#import "EWWakeUpManager.h"
#import "EWWakeUpViewController.h"
#import "EWActivity.h"
#import "EWBlurNavigationControllerDelegate.h"

@interface EWBaseNavigationController ()
@property (nonatomic, strong) EWBlurNavigationControllerDelegate *blurDelegate;
@end

@implementation EWBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    //add EWBlur Nav Delegate
    _blurDelegate = [EWBlurNavigationControllerDelegate new];
    self.delegate = _blurDelegate;
    // listern for notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentWakeUpViewWithActivity:) name:kWakeTimeNotification object:nil];
}


- (void)presentWakeUpViewWithActivity:(NSNotification *)note{
    //EWActivity *activity = note.object;
    if (![EWWakeUpManager isRootPresentingWakeUpView]) {
        //init wake up view controller
        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] initWithNibName:nil bundle:nil];
        
        //save to manager
        //[EWWakeUpManager sharedInstance].controller = controller;
        
        //push sleep view
        [self pushViewController:controller animated:YES];
        
    }else{
        DDLogInfo(@"Wake up view is already presenting, skip presenting wakeUpView");
        //NSParameterAssert([EWSession sharedSession].isWakingUp == YES);
    }
}
@end
