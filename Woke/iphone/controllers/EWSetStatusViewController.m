//
//  EWSetStatusViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/17/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWSetStatusViewController.h"
#import "EWPerson.h"
#import "JGProgressHUD.h"
#import "UIViewController+Blur.h"

@interface EWSetStatusViewController ()<UITextFieldDelegate, EWBaseViewNavigationBarButtonsDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonBottomLayoutConstraint;
@property (weak, nonatomic) IBOutlet UITextField *statusTextField;

@end

@implementation EWSetStatusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.view.backgroundColor = [UIColor clearColor];
//   
//    self.baseNavigationController.view.backgroundColor = [UIColor clearColor];
    [self.baseNavigationController setNavigationBarTransparent:YES];
    [self.statusTextField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    self.statusTextField.text = self.person.statement;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardBounds;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    
    self.buttonBottomLayoutConstraint.constant = keyboardBounds.size.height + 15;
}

- (IBAction)close:(id)sender {
    [self dismissBlurViewControllerWithCompletionHandler:nil];
}

- (IBAction)onDoneButton:(id)sender {
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    HUD.textLabel.text = @"Updating";
    [HUD showInView:self.view];
    
    [[EWPerson me] updateStatus:self.statusTextField.text completion:^(NSError *error) {
        [HUD dismissAnimated:YES];
        if (error) {
        }
        else {
            [self.statusTextField resignFirstResponder];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self onDoneButton:textField];
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
@end
