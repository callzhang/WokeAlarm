//
//  MSViewControllerHelper.m
//
//  Created by Zitao Xiong on 17/11/2014.
//  Copyright (c) 2014 Nanaimostudio. All rights reserved.
//

#import "EWViewControllerHelper.h"

@implementation UIViewController(MSHelper)

- (EWBaseNavigationController *)mainNavigationController {
    EWBaseNavigationController *mainController = (EWBaseNavigationController*)self.navigationController;
    if ([mainController isKindOfClass:[EWBaseNavigationController class]]) {
        return mainController;
    }
    
    DDLogError(@"can't find main view controller");
    DDLogError(@"nav controller is %@", self.navigationController);
    return nil;
}
@end
