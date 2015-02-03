//
//  EWAddFriendsFacebookChildViewController.m
//  Woke
//
//  Created by Zitao Xiong on 2/2/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWAddFriendsFacebookChildViewController.h"
#import "EWSocialManager.h"

@interface EWAddFriendsFacebookChildViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, readonly) NSArray *items;
@property (nonatomic, strong) NSDictionary *facebookFrineds;
@end

@implementation EWAddFriendsFacebookChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadFriendsOnWokeSection];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSArray *)items {
    return @[
             @{@"rows": @[],
               @"sectionName": ^{
                   
               }, @"showRightButton": @(YES)
               },
             ];
}

- (void)loadFriendsOnWokeSection {
    [[EWSocialManager sharedInstance] findFacebookRelatedUsersWithCompletion:^(NSArray *array, NSError *error) {
        
    NSDictionary *dictionary = @{@"rows": array,
      @"sectionName": ^{
          
      }, @"showRightButton": @(YES)
                                 };
        self.facebookFrineds = dictionary;
    }];
}
@end
