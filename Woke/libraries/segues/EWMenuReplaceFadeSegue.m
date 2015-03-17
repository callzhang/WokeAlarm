//
//  EWMenuReplaceFadeSegue.m
//  Woke
//
//  Created by Zitao Xiong on 2/7/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWMenuReplaceFadeSegue.h"
#import "EWMenuViewController.h"

/**
 *  Handle special situation in menu switching
 */
@implementation EWMenuReplaceFadeSegue
- (void)perform {
    CATransition* transition = [CATransition animation];
    
    transition.duration = 0.3;
    transition.type = kCATransitionFade;
    
    UINavigationController *nav = [UIWindow mainWindow].rootNavigationController;
    
    //Navgation View Controller:
    //Source View Controller[0] => Menu View Controller [1]
    //Designation View Controller:
    if (nav) {
        UIViewController *sourceViewController = nav.viewControllers.firstObject;//for menu it is always first object as source view contoller, 2nd is menu view controller
        UIViewController *destinationViewController = self.destinationViewController;
        
        if ([sourceViewController isKindOfClass:[destinationViewController class]]) {
            DDLogInfo(@"try to do replace fade with same class, abording pushing");
            return;
        }
        
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
