//
//  EWMainViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWMainViewController.h"
#import "VBFPopFlatButton.h"

typedef NS_ENUM(NSUInteger, MainViewMenuState) {
    MainViewMenuStateOpen,
    MainViewMenuStateClosed,
};

@interface EWMainViewController ()
@property (weak, nonatomic) IBOutlet VBFPopFlatButton *menuButton;
@property (nonatomic, assign) MainViewMenuState menuState;

@end

@implementation EWMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.menuButton.currentButtonType = buttonMenuType;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
#pragma mark -
#pragma mark - Action
- (IBAction)onMenuButton:(id)sender {
    if (self.menuState == MainViewMenuStateOpen) {
        self.menuState = MainViewMenuStateClosed;
        [self.menuButton animateToType:buttonCloseType];
    }
    else if (self.menuState == MainViewMenuStateClosed) {
        self.menuState = MainViewMenuStateOpen;
        [self.menuButton animateToType:buttonMenuType];
    }
}


@end
