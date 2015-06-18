//
//  EWBlurPresentSegue.m
//  Woke
//
//  Created by Lei Zhang on 2/10/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWBlurPushSegue.h"
#import "EWBaseNavigationController.h"
#import "EWManagedNavigiationItemsViewController.h"

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
        DDLogInfo(@"Navigation push with blur");
        EWBaseNavigationController *nav = (EWBaseNavigationController *)vc;
        [nav setDelegate:delegate];
        [nav pushViewController:self.destinationViewController animated:YES];
    }
    else if (vc.navigationController){
        DDLogInfo(@"Source VC's navigation push with blur");
        EWBaseNavigationController *nav = (EWBaseNavigationController *)vc.navigationController;
        [nav setDelegate:delegate];
        [nav pushViewController:toVC animated:YES];
    }
    else{
        DDLogInfo(@"Presentation VC with blur, with a new nav controller");
        vc.transitioningDelegate = delegate;
        vc.modalPresentationStyle = UIModalPresentationCustom;
        EWBaseNavigationController *nav = [[EWBaseNavigationController alloc] initWithRootViewController:toVC];
        //[nav setNavigationBarTransparent:YES];
        //set presented navigate
        nav.delegate = delegate;
        [vc presentViewController:nav animated:YES completion:NULL];
    }
}
@end
