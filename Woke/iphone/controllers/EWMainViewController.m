//
//  EWMainViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWMainViewController.h"
#import "VBFPopFlatButton.h"
#import "EWMenuViewController.h"
#import "UIStoryboard+Extensions.h"
#import <pop/pop.h>
#import "EWSleepViewController.h"
#import "EWWakeViewController.h"

typedef NS_ENUM(NSUInteger, MainViewMenuState) {
    MainViewMenuStateOpen,
    MainViewMenuStateClosed,
};

typedef NS_ENUM(NSUInteger, MainViewMode) {
    MainViewModeNone,
    MainViewModeSleep,
    MainViewModeWake,
};

@interface EWMainViewController ()
@property (weak, nonatomic) IBOutlet VBFPopFlatButton *menuButton;
@property (nonatomic, assign) MainViewMenuState menuState;
@property (nonatomic, strong) EWMenuViewController *menuViewController;
@property (nonatomic, strong) EWSleepViewController *sleepViewController;
@property (nonatomic, strong) EWWakeViewController *wakeViewController;
@property (nonatomic, assign) MainViewMode mode;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSegmentedControl;
@end

@implementation EWMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.menuButton.currentButtonType = buttonMenuType;
    self.menuViewController = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWMenuViewController"];
    self.sleepViewController = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWSleepViewController"];
    self.wakeViewController = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWWakeViewController"];
    self.mode = MainViewModeSleep;
    
    @weakify(self)
    self.menuViewController.tapHandler = ^ {
        @strongify(self);
        [self onMenuButton:nil];
    };
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

- (IBAction)onMenuButton:(id)sender {
    static BOOL animating = NO;
    
    if (animating) {
        return;
    }
    
    animating = YES;
    if (self.menuState == MainViewMenuStateOpen) {
        self.menuState = MainViewMenuStateClosed;
        [self.menuButton animateToType:buttonCloseType];
        [self addChildViewController:self.menuViewController];
        [self.view insertSubview:self.menuViewController.view belowSubview:self.menuButton];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            animating = NO;
        });
    }
    else if (self.menuState == MainViewMenuStateClosed) {
        self.menuState = MainViewMenuStateOpen;
        [self.menuButton animateToType:buttonMenuType];
        
        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        anim.fromValue = @(1.0);
        anim.toValue = @(0.0);
        
        @weakify(self)
        anim.completionBlock = ^(POPAnimation *animation, BOOL finished) {
            @strongify(self)
            [self.menuViewController removeFromParentViewController];
            [self.menuViewController.view removeFromSuperview];
            self.menuViewController.view.alpha = 1.0;
            animating = NO;
        };
        
        [self.menuViewController.view pop_addAnimation:anim forKey:@"fade"];
        
        [self.menuViewController closeMenu];
    }
}


@end
