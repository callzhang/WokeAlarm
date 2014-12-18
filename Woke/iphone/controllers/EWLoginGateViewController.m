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
    [[EWAccountManager shared] loginFacebookCompletion:^(BOOL isNewUser, NSError *error) {
        if (error) {
            [EWErrorManager handleError:error];
        }
        else {
            [[EWAccountManager shared] updateFromFacebookCompletion:^(NSError *error2) {
                if (error2) {
                    [EWErrorManager handleError:error2];
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
@end
