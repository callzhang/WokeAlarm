//
//  MSReplaceSegue.m
//  MakeSpace
//
//  Created by Zitao Xiong on 05/09/2014.
//  Copyright (c) 2014 Nanaimostudio. All rights reserved.
//

#import "MSReplaceSegue.h"

@implementation MSReplaceSegue

- (void)perform {
    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    if (sourceViewController.navigationController) {
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:sourceViewController.navigationController.viewControllers];
        [viewControllers replaceObjectAtIndex:viewControllers.count - 1 withObject:destinationViewController];
        [sourceViewController.navigationController setViewControllers:viewControllers animated:YES];
    }
}
@end
