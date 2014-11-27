//
//  EWLogInViewController.m
//  EarlyWorm
//
//  Created by Lei on 12/7/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWLogInViewController.h"
#import "EWPersonManager.h"
#import "EWPerson.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "EWUserManager.h"
#import "UIView+Extend.h"
#import "JGProgressHUD.h"
#import "UIViewController+Blur.h"


#define WhyFaceBook @"Lorem ipsum dolor sit amet,\nconsectertur adipisicing elit,sed do\neiusmod tempor incididunt ut\n labore et dolore magna aliqua Ut enim ad minim veniam."



@interface EWLogInViewController ()

@end

@implementation EWLogInViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    //observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView) name:kPersonLoggedIn object:nil];
    
    [self.indicator stopAnimating];
    [self updateView];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)updateView {

    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        [self.btnLoginLogout setTitle:@"Log out" forState:UIControlStateNormal];
    } else {
        [self.btnLoginLogout setTitle:@"Login with Facebook" forState:UIControlStateNormal];
    }
    
    [self.indicator stopAnimating];
    
    if ([EWPerson me]) {
        self.name.text = [EWPerson me].name;
        self.profileView.image = [EWPerson me].profilePic;
    }

}

//===============> Point of access <=================
- (IBAction)connect:(id)sender {
    [self.indicator startAnimating];
    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        DDLogError(@"*** Log out. This should never happen");
        [self logoutUser];
    } else {
        [self loginUser];
    }
}

- (IBAction)check:(id)sender {
    DDLogInfo(@"Current user: %@", [EWPerson me]);
}


- (IBAction)logout:(id)sender {
    [self.indicator startAnimating];
    if (FBSession.activeSession.state == FBSessionStateOpen) {
        [self logoutUser];
    }
}

- (IBAction)whyFacebookPopup:(id)sender {
    
    UIAlertView *alertV = [[UIAlertView alloc] initWithTitle:@"Why Facebook?" message:WhyFaceBook delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertV show];
    
}

#pragma mark - Login & Logout
- (void)loginUser {
    //[self.indicator startAnimating];
    [self.view showLoopingWithTimeout:0];
    
    [EWUserManager loginParseWithFacebookWithCompletion:^(NSError *error){
        //update UI
        [self updateView];//notification also used
        
        //leaving
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    }];
    
}

- (void)logoutUser {
    [EWUserManager logout];
    [self.indicator stopAnimating];
    self.profileView.image = [UIImage imageNamed:@"profile"];
}

- (IBAction)skip:(id)sender{
    //
}


@end
