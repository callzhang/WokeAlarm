//
//  MSReplaceFadeSegue.m
//

#import "MSReplaceFadeSegue.h"
#import "EWCategories.h"

@implementation MSReplaceFadeSegue
- (void)perform {
    CATransition* transition = [CATransition animation];
    
    transition.duration = 0.3;
    transition.type = kCATransitionFade;
    
    
    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    
    if (sourceViewController.navigationController) {
        [sourceViewController.navigationController.view.layer addAnimation:transition forKey:kCATransition];
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:sourceViewController.navigationController.viewControllers];
        [viewControllers replaceObjectAtIndex:viewControllers.count - 1 withObject:destinationViewController];
        [sourceViewController.navigationController setViewControllers:viewControllers animated:NO];
    }
    else {
        DDLogError(@"can't perform segue, sourceViewController does not have a navigaiton controller");
// replace rootViewController won't have animation. comment code
//        if ([UIWindow mainWindow].rootViewController == sourceViewController) { [UIWindow mainWindow].rootViewController = destinationViewController;
//            [[UIWindow mainWindow].rootViewController.view.layer addAnimation:transition forKey:kCATransition];
//        }
    }
}
@end
