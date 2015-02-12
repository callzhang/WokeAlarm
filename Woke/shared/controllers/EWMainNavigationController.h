//
//  EWMainNavigationController.h
//  Woke
//
//  Created by Zitao Xiong on 17/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWBaseNavigationController.h"

@interface EWMainNavigationController : EWBaseNavigationController
- (UIBarButtonItem *)menuBarButtonItem;
- (void)toogleMenuCompletion:(VoidBlock)completion;
@end


@interface UIViewController(EWMainNavigationController)
@property (nonatomic, readonly) EWMainNavigationController *mainNavigationController;
@end