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
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) EWAddFriendsContactsChildViewController *contactsChildViewController;
@property (nonatomic, strong) EWAddFriendsFacebookChildViewController *facebookChildViewController;
@property (nonatomic, strong) EWAddFriendsSearchChildViewController *searchChildViewController;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@end

@implementation EWAddFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Add Friends";
    
    @weakify(self);
    [[self.segmentedControl rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(UISegmentedControl *sender) {
        @strongify(self);
        NSInteger index = sender.selectedSegmentIndex;
        if (index == 0) {
            self.facebookChildViewController.view.hidden = NO;
            self.contactsChildViewController.view.hidden = YES;
            self.searchChildViewController.view.hidden = YES;
        }
        else if (index == 1) {
            self.facebookChildViewController.view.hidden = YES;
            self.contactsChildViewController.view.hidden = NO;
            self.searchChildViewController.view.hidden = YES;
        }
        else if (index == 2) {
            self.facebookChildViewController.view.hidden = YES;
            self.contactsChildViewController.view.hidden = YES;
            self.searchChildViewController.view.hidden = NO;
        }
    }];
    
    self.segmentedControl.selectedSegmentIndex = 0;
}
@end
