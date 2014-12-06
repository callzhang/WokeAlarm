//
//  EWBaseNavigationController.m
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWBaseNavigationController.h"
#import "VBFPopFlatButton.h"
#import "EWMenuViewController.h"
#import <pop/pop.h>

typedef NS_ENUM(NSUInteger, MainViewMenuState) {
    MainViewMenuStateOpen,
    MainViewMenuStateClosed,
};

@interface EWBaseNavigationController ()
@property (nonatomic, strong) EWMenuViewController *menuViewController;
@property (nonatomic, assign) MainViewMenuState menuState;
@end

@implementation EWBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.menuViewController = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWMenuViewController"];
    @weakify(self)
    self.menuViewController.tapHandler = ^ {
        @strongify(self);
        [self onMenuButton:nil];
    };
    float statusBar = 20;
    float navigationBar = 44;
    float mWidth = 25;
    float mHeight = 25;
    float mY = ((navigationBar) - mHeight ) / 2.0 + statusBar;
    float mX = mY - statusBar;
    
    self.menuButton = [[VBFPopFlatButton alloc] initWithFrame:CGRectMake(mX, mY, mWidth, mHeight) buttonType:buttonMenuType buttonStyle:buttonPlainStyle animateToInitialState:NO];
    [self.menuButton addTarget:self action:@selector(onMenuButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.menuButton];
}

- (void)onMenuButton:(VBFPopFlatButton *)sender {
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
        [self.menuViewController beginAppearanceTransition:YES animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            animating = NO;
        });
    }
    else if (self.menuState == MainViewMenuStateClosed) {
        self.menuState = MainViewMenuStateOpen;
        [self.menuButton animateToType:buttonMenuType];
        
        [self.menuViewController willMoveToParentViewController:nil];
        [self.menuViewController beginAppearanceTransition:NO animated:YES];
        
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
