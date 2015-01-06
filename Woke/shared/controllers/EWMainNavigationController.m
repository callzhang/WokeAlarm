//
//  EWMainNavigationController.m
//  Woke
//
//  Created by Zitao Xiong on 17/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWMainNavigationController.h"
#import "EWMenuViewController.h"
#import "EWBlurNavigationControllerDelegate.h"
#import <pop/pop.h>

typedef NS_ENUM(NSUInteger, MainViewMenuState) {
    MainViewMenuStateOpen,
    MainViewMenuStateClosed,
};

@interface EWMainNavigationController()
@property (nonatomic, strong) EWMenuViewController *menuViewController;
@property (nonatomic, assign) MainViewMenuState menuState;
@property (nonatomic, strong) EWBlurNavigationControllerDelegate *blurDelegate;

@end

@implementation EWMainNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.menuViewController = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:@"EWMenuViewController"];
    @weakify(self)
    self.menuViewController.tapHandler = ^ {
        @strongify(self);
        [self toogleMenuCompletion:^{
            
        }];
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //add EWBlur Nav Delegate
//    _blurDelegate = [EWBlurNavigationControllerDelegate new];
//    self.delegate = _blurDelegate;
    // listern for notification
    [[NSNotificationCenter defaultCenter] addObserverForName:kNewMediaNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        //TODO
    }];
}

- (void)onMenuButton:(UIButton *)sender {
    [self toogleMenuCompletion:nil];
}

- (void)toogleMenuCompletion:(VoidBlock)completion {
    
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
        _menuViewController.mainNavigationController = self;
    }
    
    if (menuViewController == nil) {
        _menuViewController.mainNavigationController = nil;
        _menuViewController = nil;
    }
}

@end

@implementation UIViewController(EWMainNavigationController)

- (EWMainNavigationController *)mainNavigationController {
    EWMainNavigationController *mainController = (EWMainNavigationController*)self.navigationController;
    if ([mainController isKindOfClass:[EWMainNavigationController class]]) {
        return mainController;
    }
    
    DDLogError(@"can't find EWMainNavigationController");
    DDLogError(@"nav controller is %@", self.navigationController);
    return nil;
}
@end