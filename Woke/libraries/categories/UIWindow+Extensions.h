//
//  UIStoryBoard+Extensions.h
//  MakeSpace
//
//  Created by Zitao Xiong on 21/09/2014.
//  Copyright (c) 2014 Nanaimostudio. All rights reserved.
//

#import "EWBaseNavigationController.h"
@import Foundation;

@interface UIWindow (Extensions)
/**
 *  Helper method to get the main window in current applicaiton. 
 *  The main window comes from Appdelegate
 *
 *  @return main window for current application
 */
+ (UIWindow *)mainWindow;

/**
 *  Helper method to get the root navigation controller as MSMainNavigationController
 *  if rootViewController is not a MSMainNavigationController, it will return nil;
 *
 *  @return MSMainNavigationController
 */
- (EWBaseNavigationController *)rootNavigationController;
@end
