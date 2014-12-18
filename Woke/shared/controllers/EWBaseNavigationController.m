//
//  EWBaseNavigationController.m
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWBaseNavigationController.h"
//#import "VBFPopFlatButton.h"
#import "EWMenuViewController.h"
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

@interface EWBaseNavigationController ()<UINavigationControllerDelegate>
@property (nonatomic, assign) BOOL barTransparent;
@end

@implementation EWBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

@implementation UIViewController(EWBaseNavigationController)

- (EWBaseNavigationController *)baseNavigationController {
    EWBaseNavigationController *mainController = (EWBaseNavigationController*)self.navigationController;
    if ([mainController isKindOfClass:[EWBaseNavigationController class]]) {
        return mainController;
    }
    
    DDLogError(@"can't find EWBaseNavigationController");
    DDLogError(@"nav controller is %@", self.navigationController);
    return nil;
}
@end

//- (void)presentWakeUpViewWithActivity:(NSNotification *)note{
//    DDLogDebug(@"Presenting Wake Up View");
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
//}