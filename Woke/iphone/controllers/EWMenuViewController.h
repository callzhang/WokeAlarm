//
//  EWMenuViewController.h
//  Woke
//
//  Created by Zitao Xiong on 21/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWBaseViewController.h"

typedef void(^MenuBackgroundTapHanlder)(void);
@interface EWMenuViewController : EWBaseViewController


@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (nonatomic, copy) MenuBackgroundTapHanlder tapHandler;
@property (nonatomic, weak) EWBaseNavigationController *baseNavigationController;

- (void)closeMenu;

@end
