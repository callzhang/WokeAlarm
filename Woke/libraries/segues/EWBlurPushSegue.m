//
//  EWBlurPresentSegue.m
//  Woke
//
//  Created by Lei Zhang on 2/10/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWBlurPushSegue.h"
#import "EWBaseNavigationController.h"

//it must stay static otherwise it will dealloc prematurely
static EWBlurNavigationControllerDelegate *delegate;

@implementation EWBlurPushSegue
- (void)perform {
    UIViewController *vc = self.sourceViewController;
	if (!delegate) {
		delegate = [EWBlurNavigationControllerDelegate new];
	}
	
    if ([vc isKindOfClass:[UINavigationController class]]) {
        EWBaseNavigationController *nav = (EWBaseNavigationController *)vc;
        [nav setDelegate:delegate];
        [nav pushViewController:self.destinationViewController animated:YES];
        [nav addNavigationButtons];
    }
    else if (vc.navigationController){
        EWBaseNavigationController *nav = (EWBaseNavigationController *)vc.navigationController;
        [nav setDelegate:delegate];
        [nav pushViewController:self.destinationViewController animated:YES];
        [nav addNavigationButtons];
    }
    else{
        vc.transitioningDelegate = delegate;
        if (vc.navigationController) {
            vc.navigationController.delegate = delegate;
        }
        vc.modalPresentationStyle = UIModalPresentationCustom;
        EWBaseNavigationController *nav = [[EWBaseNavigationController alloc] initWithRootViewController:self.destinationViewController];
        [nav addNavigationButtons];
        [nav setNavigationBarTransparent:YES];
        [vc presentViewController:nav animated:YES completion:NULL];
    }
}
@end
