//
//  EWVoiceViewController.m
//  Woke
//
//  Created by Zitao Xiong on 2/7/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWVoiceViewController.h"
#import "EWReceivedVoiceChildViewController.h"
#import "EWSentVoiceChildViewController.h"
#import "UISegmentedControl+RACSignalSupport.h"

@interface EWVoiceViewController ()
@property (nonatomic, strong) EWReceivedVoiceChildViewController *receivedVoiceChildViewController;
@property (nonatomic, strong) EWSentVoiceChildViewController *sentVoiceChildViewController;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIView *sentView;
@property (weak, nonatomic) IBOutlet UIView *receivedView;
@end

@implementation EWVoiceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.mainNavigationController.menuBarButtonItem;
    self.title = @"Voice";
    
    @weakify(self);
    [[self.segmentedControl rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(UISegmentedControl *sender) {
       @strongify(self);
        NSInteger index = sender.selectedSegmentIndex;
        if (index == 0) {
            self.receivedVoiceChildViewController.view.hidden = NO;
            self.sentVoiceChildViewController.view.hidden = YES;
            [self.view bringSubviewToFront:self.receivedView];
        }
        else {
            self.receivedVoiceChildViewController.view.hidden = YES;
            self.sentVoiceChildViewController.view.hidden = NO;
            [self.view bringSubviewToFront:self.sentView];
        }
    }];
    
    self.receivedVoiceChildViewController.view.hidden = NO;
    self.sentVoiceChildViewController.view.hidden = YES;
    [self.view bringSubviewToFront:self.receivedView];
}


#pragma mark - Status Bar
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
@end
