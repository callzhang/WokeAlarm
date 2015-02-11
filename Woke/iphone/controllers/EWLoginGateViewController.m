//
//  EWLoginGateViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWLoginGateViewController.h"
#import "EWAccountManager.h"
#import "EWErrorManager.h"
#import "EWUIUtil.h"

@interface EWLoginGateViewController ()

@end

@implementation EWLoginGateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.mainNavigationController setNavigationBarTransparent:YES];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)onContinueWithFacebookButton:(id)sender {
    [self.view showLoopingWithTimeout:0];
    [[EWAccountManager shared] loginFacebookCompletion:^(NSError *error) {
        if (error) {
            [EWErrorManager handleError:error];
            [self.view showFailureNotification:[NSString stringWithFormat:@"Failed to log in: %@", error.localizedDescription]];
        }
        else {
            [[EWAccountManager shared] updateFromFacebookCompletion:^(NSError *error2) {
                if (error2) {
                    [self.view showFailureNotification:[NSString stringWithFormat:@"Failed to log in: %@", error2.localizedDescription]];
                    [EWErrorManager handleError:error2];
                } else {
                    //show success view on top view
                    [EWUIUtil showSuccessHUBWithString:@"Logged in"];
                }
            }];
            
            [self performSegueWithIdentifier:@"TempShowMainViewSegue" sender:self];
        }
    }];
}

- (IBAction)unwindToLoginGateViewController:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"unwindFromMenuLogout"]) {
        [[EWAccountManager shared] logout];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    UIViewController *toViewController = segue.destinationViewController;
    if (!EWAccountManager.isLoggedIn) {
        [toViewController.view showLoopingWithTimeout:0];
    }
}
@end
