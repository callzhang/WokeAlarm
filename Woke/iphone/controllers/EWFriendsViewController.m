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
    
    //search
    _resultController = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:NSStringFromClass([EWPersonSearchResultTableViewController class])];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:_resultController];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.searchController.searchBar.scopeButtonTitles = searchScopes;
    self.searchController.searchBar.delegate = self;
    self.definesPresentationContext = YES;
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


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - UISearchResultsUpdating

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *searchString = [self.searchController.searchBar text];
    
    NSString *scope = searchScopes[self.searchController.searchBar.selectedScopeButtonIndex];
    
    [self updateFilteredContentForProductName:searchString scope:scope completion:^(NSArray *array, NSError *error) {
        if (!array) {
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

#pragma mark - Content Filtering
- (void)updateFilteredContentForProductName:(NSString *)searchString scope:(NSString *)scope completion:(ArrayBlock)block {
    
    NSString *strippedString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    
    NSInteger index = [searchScopes indexOfObject:scope];
    switch (index) {
        case 0:{//contacts, local search
            if (strippedString.length == 0 || !searchString) {
                block(nil, nil);
                return;
            }
            NSArray *searchItems = [strippedString componentsSeparatedByString:@" "];
            NSArray *result = [_friends bk_select:^BOOL(id obj) {
                for (EWPerson *person in _friends) {
                    for (NSString *searchText in searchItems) {
                        if ([person.firstName isEqualToString:searchString]) {
                            return YES;
                        }else if([person.lastName isEqualToString:searchString]){
                            return YES;
                        }else if ([person.email isEqualToString:searchString]){
                            return YES;
                        }
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
