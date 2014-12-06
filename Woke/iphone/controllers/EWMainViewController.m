//
//  EWMainViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWMainViewController.h"
#import "VBFPopFlatButton.h"
#import "UIStoryboard+Extensions.h"
#import "EWSleepViewController.h"
#import "EWWakeViewController.h"



typedef NS_ENUM(NSUInteger, MainViewMode) {
    MainViewModeNone,
    MainViewModeSleep,
    MainViewModeWake,
};

@interface EWMainViewController ()

@property (nonatomic, strong) EWSleepViewController *sleepViewController;
@property (nonatomic, strong) EWWakeViewController *wakeViewController;
@property (nonatomic, assign) MainViewMode mode;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSegmentedControl;
@end

@implementation EWMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sleepViewController = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWSleepViewController"];
    self.wakeViewController = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWWakeViewController"];
    self.mode = MainViewModeSleep;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
#pragma mark -
- (void)setMode:(MainViewMode)mode {
    if (_mode != mode) {
        if (_mode == MainViewModeSleep) {
            [self.sleepViewController.view removeFromSuperview];
            [self.sleepViewController removeFromParentViewController];
        }
        else if (_mode == MainViewModeWake) {
            [self.wakeViewController.view removeFromSuperview];
            [self.wakeViewController removeFromParentViewController];
        }
        
        _mode = mode;
        if (_mode == MainViewModeSleep) {
            [self addChildViewController:self.sleepViewController];
            [self.view insertSubview:self.sleepViewController.view belowSubview:self.modeSegmentedControl];
        }
        else if (_mode == MainViewModeWake) {
            [self addChildViewController:self.wakeViewController];
            [self.view insertSubview:self.wakeViewController.view belowSubview:self.modeSegmentedControl];
        }
    }
}
#pragma mark - Action
- (IBAction)onSegmentedValueChanged:(UISegmentedControl *)sender {
    NSInteger index = sender.selectedSegmentIndex;
    switch (index) {
        case 0:
            self.mode = MainViewModeSleep;
            break;
        case 1:
            self.mode = MainViewModeWake;
            break;
        default:
            break;
    }
}

@end
