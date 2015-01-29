//
//  EWFriendsViewController.m
//  Woke
//
//  Created by Lei Zhang on 1/28/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWFriendsViewController.h"
#import "EWPersonSearchResultTableViewController.h"
#import "EWAlarmManager.h"
#import "NSArray+BlocksKit.h"
#import "EWSocialManager.h"
#import "EWUIUtil.h"
#define searchScopes    @[@"Contacts", @"Facebook", @"Server", @"Search"]

@interface EWFriendsViewController ()<UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating>
@property (strong, nonatomic) NSArray *friends;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) EWPersonSearchResultTableViewController *resultController;
@end

@implementation EWFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //view
    self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFriends:)];
    
    //data
    self.friends = [EWPerson myFriends];
    DDLogVerbose(@"Showing friends %@", [_friends valueForKey:EWPersonAttributes.firstName]);
    
    //search
    _resultController = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:NSStringFromClass([EWPersonSearchResultTableViewController class])];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:_resultController];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.searchController.searchBar.scopeButtonTitles = searchScopes;
    self.searchController.searchBar.delegate = self;
    self.definesPresentationContext = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //navigation
    //[EWUIUtil addTransparantNavigationBarToViewController:self];
    
    //bg
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"woke-background"]];
    bg.frame = [UIWindow mainWindow].frame;
    [self.view insertSubview:bg atIndex:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _friends.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCellIdentifier" forIndexPath:indexPath];
    
    EWPerson *friend = _friends[indexPath.row];
    cell.textLabel.text = friend.name;
    cell.detailTextLabel.text = friend.distanceString;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    EWPerson *friend = _friends[indexPath.row];
    DDLogInfo(@"Did seleted %@", friend.name);
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - UI
- (IBAction)addFriends:(id)sender{
    EWAlert(@"Zitao please add the view here");
}

#pragma mark - UISearchResultsUpdating

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *searchString = [self.searchController.searchBar text];
    
    NSString *scope = searchScopes[self.searchController.searchBar.selectedScopeButtonIndex];
    
    [self updateFilteredContentForProductName:searchString scope:scope completion:^(NSArray *array, NSError *error) {
        if (!array || (error && array.count == 0)) {
            DDLogError(@"Failed search with error:%@", error);
            return;
        }
        EWPersonSearchResultTableViewController *resultViewController = (EWPersonSearchResultTableViewController *)self.searchController.searchResultsController;
        resultViewController.searchResults = array;
        [resultViewController.tableView reloadData];
    }];
}


#pragma mark - UISearchBarDelegate
// Workaround for bug: -updateSearchResultsForSearchController: is not called when scope buttons change
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self updateSearchResultsForSearchController:self.searchController];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self updateSearchResultsForSearchController:self.searchController];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    NSString *scope = searchScopes[self.searchController.searchBar.selectedScopeButtonIndex];
    if ([scope isEqualToString:@"Contacts"]) {
        [self updateSearchResultsForSearchController:self.searchController];
    }
}

#pragma mark - Content Filtering
- (void)updateFilteredContentForProductName:(NSString *)searchString scope:(NSString *)scope completion:(ArrayBlock)block {
    
    NSString *strippedString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    
    NSInteger index = [searchScopes indexOfObject:scope];
    switch (index) {
        case 0:{//contacts, local search
            if (strippedString.length == 0 || !searchString) {
                block(@[], nil);
                return;
            }
            
            NSArray *searchItems = [strippedString componentsSeparatedByString:@" "];
            NSArray *result = [_friends bk_select:^BOOL(EWPerson *person) {
                for (NSString *searchText in searchItems) {
                    if ([person.firstName rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        return YES;
                    }else if([person.lastName rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound){
                        return YES;
                    }else if ([person.email isEqualToString:[searchText lowercaseString]]){
                        return YES;
                    }
                }
                return NO;
            }];
            
            block(result, nil);
        }
            break;
        case 1:{//Facebook, saerch for facebook
            [[EWSocialManager sharedInstance] searchForFacebookFriendsWithCompletion:^(NSArray *array, NSError *error) {
                block(array, error);
            }];
        }
            break;
        case 2:{//Search name from server
            [[EWSocialManager sharedInstance] findAddressbookUsersFromContactsWithCompletion:^(NSArray *array, NSError *error) {
                block(array, error);
            }];
        }
            break;
        case 3:{
            [[EWSocialManager sharedInstance] searchUserWithPhrase:searchString completion:^(NSArray *array, NSError *error) {
                block(array, error);
            }];
        }
        default:
            break;
    }
}

@end
