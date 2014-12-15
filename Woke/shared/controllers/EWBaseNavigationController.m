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
#import "EWActivityManager.h"
#import "EWWakeUpManager.h"
#import "EWWakeUpViewController.h"
#import "EWActivity.h"
#import "EWBlurNavigationControllerDelegate.h"



//#import "EWActivityManager.h"
//#import "EWWakeUpManager.h"
//#import "EWWakeUpViewController.h"
//#import "EWActivity.h"
#import "EWBlurNavigationControllerDelegate.h"
#import "NYXImagesKit.h"
#import "UIImage+Extensions.h"

typedef NS_ENUM(NSUInteger, MainViewMenuState) {
    MainViewMenuStateOpen,
    MainViewMenuStateClosed,
};

@interface EWBaseNavigationController ()<UINavigationControllerDelegate>
@property (nonatomic, strong) EWMenuViewController *menuViewController;
@property (nonatomic, assign) MainViewMenuState menuState;
@property (nonatomic, strong) EWBlurNavigationControllerDelegate *blurDelegate;

@property (nonatomic, assign) BOOL barTransparent;
@end

@implementation EWBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.menuViewController = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWMenuViewController"];
    @weakify(self)
    self.menuViewController.tapHandler = ^ {
        @strongify(self);
        [self toogleMenuCompletion:^{
            
        }];
    };
    float statusBar = 20;
    float navigationBar = 44;
    float mWidth = 25;
    float mHeight = 25;
    float mY = ((navigationBar) - mHeight ) / 2.0 + statusBar;
    float mX = mY - statusBar;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //add EWBlur Nav Delegate
//    _blurDelegate = [EWBlurNavigationControllerDelegate new];
//    self.delegate = _blurDelegate;
    // listern for notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentWakeUpViewWithActivity:) name:kWakeTimeNotification object:nil];
}


- (void)presentWakeUpViewWithActivity:(NSNotification *)note{
    DDLogDebug(@"Presenting Wake Up View");
    //TODO: implement the presenting process

//    //EWActivity *activity = note.object;
//    if (![EWWakeUpManager isRootPresentingWakeUpView]) {
//        //init wake up view controller
//        EWWakeUpViewController *controller = [[EWWakeUpViewController alloc] initWithNibName:nil bundle:nil];
//        
//        //save to manager
//        //[EWWakeUpManager sharedInstance].controller = controller;
//        
//        //push sleep view
//        [self pushViewController:controller animated:YES];
//        
//    }else{
//        DDLogInfo(@"Wake up view is already presenting, skip presenting wakeUpView");
//        //NSParameterAssert([EWSession sharedSession].isWakingUp == YES);
//    }
}

- (void)onMenuButton:(VBFPopFlatButton *)sender {
    [self toogleMenuCompletion:nil];
}

- (void)toogleMenuCompletion:(void (^)(void))completion {
    
    static BOOL animating = NO;
    
    if (animating) {
        return;
    }
    
    animating = YES;
    if (self.menuState == MainViewMenuStateOpen) {
        //Open Menu
        self.menuState = MainViewMenuStateClosed;
//        [self.menuButton animateToType:buttonCloseType];
        [self addChildViewController:self.menuViewController];
        [self.view addSubview:self.menuViewController.view];
//        [self.view insertSubview:self.menuViewController.view belowSubview:self.menuButton];
        [self.menuViewController beginAppearanceTransition:YES animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            animating = NO;
            if (completion) {
                completion();
            }
        });
    }
    else if (self.menuState == MainViewMenuStateClosed) {
        //Close Menu
        self.menuState = MainViewMenuStateOpen;
//        [self.menuButton animateToType:buttonMenuType];
        
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
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion();
                };
            });
        };
        
        [self.menuViewController.view pop_addAnimation:anim forKey:@"fade"];
        
        [self.menuViewController closeMenu];
    }
}
#pragma mark - Helper
- (UIBarButtonItem *)menuBarButtonItem {
    UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton setImage:[UIImage imageNamed:@"woke-nav-menu"] forState:UIControlStateNormal];
    menuButton.frame = CGRectMake(0, 0, 35, 35);
    [menuButton addTarget:self action:@selector(onMenuButton:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
    
    return buttonItem;
}

#pragma mark - Accessor

- (void)setMenuViewController:(EWMenuViewController *)menuViewController {
    if (_menuViewController != menuViewController) {
        _menuViewController = menuViewController;
        _menuViewController.baseNavigationController = self;
    }
    
    if (menuViewController == nil) {
        _menuViewController.baseNavigationController = nil;
        _menuViewController = nil;
    }
}

- (void)setNavigationBarTransparent:(BOOL)transparent {
    
    if (self.barTransparent == transparent) {
        return;
    }
    
    self.barTransparent = transparent;
    
    if (transparent) {
        [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        self.navigationBar.shadowImage = [UIImage new];
        self.navigationBar.translucent = YES;
    }
    else {
        UIImage *image = [UIImage imageWithColor:[UIColor colorWithHue:0.555f saturation:1.f brightness:0.855f alpha:1.f]];
        [self.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        self.navigationBar.shadowImage = nil;
//        self.navigationBar.barTintColor = [UIColor colorWithHue:0.555f saturation:1.f brightness:0.855f alpha:1.f];
//        self.navigationBar.tintColor = [UIColor colorWithHue:0.555f saturation:1.f brightness:0.855f alpha:1.f];
//        self.navigationBar.barTintColor = [UIColor blueColor];
        self.navigationBar.translucent = YES;
    }
}
@end
