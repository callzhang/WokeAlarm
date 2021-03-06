//
//  EWMenuViewController.h
//  Woke
//
//  Created by Zitao Xiong on 21/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWManagedNavigiationItemsViewController.h"

typedef void(^MenuBackgroundTapHanlder)(void);
@interface EWMenuViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (nonatomic, copy) MenuBackgroundTapHanlder tapHandler;
@property (nonatomic, weak) EWMainNavigationController *mainNavigationController;

- (void)closeMenu;

@end
