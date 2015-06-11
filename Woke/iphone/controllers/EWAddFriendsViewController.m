//
//  EWAddFriendsViewController.m
//  Woke
//
//  Created by Zitao Xiong on 2/2/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWAddFriendsViewController.h"
#import "EWAddFriendsContactsChildViewController.h"
#import "EWAddFriendsFacebookChildViewController.h"
#import "EWAddFriendsSearchChildViewController.h"
#import "UISegmentedControl+RACSignalSupport.h"

@interface EWAddFriendsViewController ()
@property (nonatomic, strong) EWAddFriendsContactsChildViewController *contactsChildViewController;
@property (nonatomic, strong) EWAddFriendsFacebookChildViewController *facebookChildViewController;
@property (nonatomic, strong) EWAddFriendsSearchChildViewController *searchChildViewController;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIView *containerViewFacebook;
@property (weak, nonatomic) IBOutlet UIView *containerViewContacts;
@property (weak, nonatomic) IBOutlet UIView *containerViewSearch;
@end

@implementation EWAddFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSParameterAssert(_facebookChildViewController);
    NSParameterAssert(_contactsChildViewController);
    NSParameterAssert(_searchChildViewController);
    
    self.title = @"Add Friends";
    
    @weakify(self);
    [[self.segmentedControl rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(UISegmentedControl *sender) {
        @strongify(self);
        [self.searchChildViewController.searchController setActive:NO];
        NSInteger index = sender.selectedSegmentIndex;
        if (index == 0) {
            [self showFacebook];
        }
        else if (index == 1) {
            [self showContacts];
        }
        else if (index == 2) {
            [self showSearch];
        }
    }];
    
    [self showFacebook];
}

- (void)showFacebook {
    self.facebookChildViewController.view.hidden = NO;
    self.contactsChildViewController.view.hidden = YES;
    self.searchChildViewController.view.hidden = YES;
    
    [self.view bringSubviewToFront:self.containerViewFacebook];
}

- (void)showContacts {
    self.facebookChildViewController.view.hidden = YES;
    self.contactsChildViewController.view.hidden = NO;
    self.searchChildViewController.view.hidden = YES;
    
    [self.view bringSubviewToFront:self.containerViewContacts];
}

- (void)showSearch {
    self.facebookChildViewController.view.hidden = YES;
    self.contactsChildViewController.view.hidden = YES;
    self.searchChildViewController.view.hidden = NO;
    
    [self.view bringSubviewToFront:self.containerViewSearch];
    
}
@end
