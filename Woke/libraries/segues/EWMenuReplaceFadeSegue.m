//
//  EWMenuReplaceFadeSegue.m
//  Woke
//
//  Created by Zitao Xiong on 2/7/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWMenuReplaceFadeSegue.h"
#import "EWMenuViewController.h"

@implementation EWMenuReplaceFadeSegue
- (void)perform {
    CATransition* transition = [CATransition animation];
    
    transition.duration = 0.3;
    transition.type = kCATransitionFade;
    
    
//    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    UINavigationController *nav = [UIWindow mainWindow].rootNavigationController;
    
    if (nav) {
        [nav.view.layer addAnimation:transition forKey:kCATransition];
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:nav.viewControllers];
        if ([viewControllers.lastObject isKindOfClass:[EWMenuViewController class]]) {
            [viewControllers removeLastObject];
        }
        [viewControllers replaceObjectAtIndex:viewControllers.count - 1 withObject:destinationViewController];
        [nav setViewControllers:viewControllers animated:NO];
    }
    else {
        DDLogError(@"can't perform segue, sourceViewController does not have a navigaiton controller");
    }
}
@end
