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

@implementation EWBlurPresentSegue
- (void)perform {
    UIViewController *vc = self.sourceViewController;
    UIViewController *toVC = self.destinationViewController;
    if ([vc isKindOfClass:[UINavigationController class]]) {
        DDLogError(@"Blur present cannot be used directly on UINavigationController");
    }
    else{
        EWBaseNavigationController *nav;
        if (toVC.navigationController) {
            nav = (EWBaseNavigationController *)toVC.navigationController;
        } else{
            nav = [[EWBaseNavigationController alloc] initWithRootViewController:self.destinationViewController];
            //nav.delegate = delegate;
            [nav addNavigationButtons];
            [nav setNavigationBarTransparent:YES];
        }
        
        [vc presentViewControllerWithBlurBackground:nav];
    }
}
@end
