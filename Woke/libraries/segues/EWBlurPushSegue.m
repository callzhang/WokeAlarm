//
//  EWBlurPresentSegue.m
//  Woke
//
//  Created by Lei Zhang on 2/10/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWBlurPushSegue.h"
#import "EWBaseNavigationController.h"
#import "EWBaseViewController.h"

//it must stay static otherwise it will dealloc prematurely
static EWBlurNavigationControllerDelegate *delegate;

@implementation EWBlurPushSegue
- (void)perform {
    UIViewController *vc = self.sourceViewController;
    UIViewController *toVC = self.destinationViewController;
	if (!delegate) {
		delegate = [EWBlurNavigationControllerDelegate new];
	}
	
    if ([vc isKindOfClass:[UINavigationController class]]) {
        EWBaseNavigationController *nav = (EWBaseNavigationController *)vc;
        [nav setDelegate:delegate];
        [nav pushViewController:self.destinationViewController animated:YES];
        toVC = nav.topViewController;
        if ([toVC isKindOfClass:[EWBaseViewController class]]) {
            [(EWBaseViewController *)toVC addNavigationBarButtons];
        }
    }
    else if (vc.navigationController){
        EWBaseNavigationController *nav = (EWBaseNavigationController *)vc.navigationController;
        [nav setDelegate:delegate];
        [nav pushViewController:self.destinationViewController animated:YES];
        if ([vc isKindOfClass:[EWBaseViewController class]]) {
            [(EWBaseViewController *)vc addNavigationBarButtons];
        }
    }
    else{
        vc.transitioningDelegate = delegate;
        if (vc.navigationController) {
            vc.navigationController.delegate = delegate;
        }
        vc.modalPresentationStyle = UIModalPresentationCustom;
        EWBaseNavigationController *nav = [[EWBaseNavigationController alloc] initWithRootViewController:self.destinationViewController];
        [nav setNavigationBarTransparent:YES];
        [vc presentViewController:nav animated:YES completion:NULL];
        if ([vc isKindOfClass:[EWBaseViewController class]]) {
            [(EWBaseViewController *)vc addNavigationBarButtons];
        }
    }
}
@end
