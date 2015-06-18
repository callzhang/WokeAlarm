//
//  EWBlurPresentSegue.m
//  Woke
//
//  Created by Lei Zhang on 2/10/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWBlurPresentSegue.h"
#import "EWBlurNavigationControllerDelegate.h"
#import "UIViewController+Blur.h"
#import "EWManagedNavigiationItemsViewController.h"

@implementation EWBlurPresentSegue
- (void)perform {
    EWBaseNavigationController *nav;
    UIViewController *fromVC = self.sourceViewController;
    UIViewController *toVC = self.destinationViewController;
    if ([toVC isKindOfClass:[UINavigationController class]]) {
        nav = (EWBaseNavigationController *)toVC;
    }
    else if (toVC.navigationController) {
        nav = (EWBaseNavigationController *)toVC.navigationController;
    }
    else{
        nav = [[EWBaseNavigationController alloc] initWithRootViewController:toVC];
        //[nav setNavigationBarTransparent:YES];
    }
        
    [fromVC presentViewControllerWithBlurBackground:nav];
}
@end
