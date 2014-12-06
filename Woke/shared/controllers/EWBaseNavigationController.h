//
//  EWBaseNavigationController.h
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VBFPopFlatButton;
@interface EWBaseNavigationController : UINavigationController
@property (strong, nonatomic) VBFPopFlatButton *menuButton;

/**
 Present EWWakeUpViewController on rootView.
 Also it will register the presented wake up view controller as a retained value to prevent premature deallocation in ARC.
 @discussion If rootView is displaying anything else, it will dismiss other view first.
 */

- (void)presentWakeUpViewWithActivity:(NSNotification *)activity;

@end
