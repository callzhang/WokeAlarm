//
//  EWBaseViewController.h
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWMainNavigationController.h"
#import "EWBaseViewController.h"
//
@protocol EWBaseViewNavigationBarButtonsDelegate
@optional
- (IBAction)close:(id)sender;
- (IBAction)more:(id)sender;
@end

@interface EWManagedNavigiationItemsViewController : EWBaseViewController<EWBaseViewNavigationBarButtonsDelegate>
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, readonly) EWMainNavigationController *mainNavigationController;
- (void)addNavigationBarButtons;
@end
