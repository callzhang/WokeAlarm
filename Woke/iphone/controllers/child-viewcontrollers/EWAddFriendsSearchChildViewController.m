//
//  EWAddFriendsSearchChildViewController.m
//  Woke
//
//  Created by Zitao Xiong on 2/2/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWAddFriendsSearchChildViewController.h"
#import "EWBaseTableViewController.h"
#import "EWAddFriendsTableViewCell.h"
#import "EWSocialManager.h"
#import "EWBaseViewController.h"
#import "EWUIUtil.h"
#import "NSTimer+BlocksKit.h"

@interface EWAddFriendsSearchChildViewController ()<UISearchResultsUpdating, UISearchControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *items;
@end

@implementation EWAddFriendsSearchChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    [self.searchController.searchBar sizeToFit];
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
   
    self.definesPresentationContext = YES;
}

#pragma mark - <UITableViewDataSource>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWAddFriendsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.addFriendsCell];
    
    EWPerson *person = self.items[indexPath.row];
    
    cell.person = person;
    
    return cell;
}

#pragma mark - <UISearchResultsUpdating>
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.searchBar.text.length == 0) {
        return;
    }
    static NSTimer *timer;
    [timer invalidate];
    timer = [NSTimer bk_scheduledTimerWithTimeInterval:1 block:^(NSTimer *timer) {
        [EWUIUtil showWatingHUB];
        [[EWSocialManager sharedInstance] searchUserWithPhrase:searchController.searchBar.text
                                                    completion:^(NSArray *array, NSError *error) {
                                                        if (!error) {
                                                            self.items = array;
                                                            [EWUIUtil dismissHUD];
                                                        }
                                                        else {
                                                            DDLogError(@"search error: %@", error);
                                                            [EWUIUtil showFailureHUBWithString:@"Failed"];
                                                        }
                                                        [self.tableView reloadData];
                                                    }];
    } repeats:NO];
    
}
@end

