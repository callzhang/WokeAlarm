//
//  EWFriendsViewController.m
//  Woke
//
//  Created by Zitao Xiong on 2/1/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWFriendsViewController.h"
#import "CGLAlphabetizer.h"
#import "EWFriendsViewTableViewCell.h"
#import "EWProfileViewController.h"
#import "UIStoryboard+Extensions.h"
#import "UIBarButtonItem+BlocksKit.h"
#import "UIViewController+Blur.h"

#define kFriendViewCellSectionLabelID 991

@interface EWFriendsViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *friends;

@property (nonatomic) NSDictionary *alphabetizedDictionary;
@property (nonatomic) NSArray *sectionIndexTitles;
@end

@implementation EWFriendsViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.friends) {
        self.friends = [EWPerson myFriends];
    }
    
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.sectionIndexColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Friends" style:UIBarButtonItemStylePlain target:self action:@selector(onAddFriendsBarButtonItem:)];
    
}

- (void)onAddFriendsBarButtonItem:(UIBarButtonItem *)item {
    [self performSegueWithIdentifier:MainStoryboardIDs.segues.friendsToAddFriends sender:self];
}

- (void)setFriends:(NSArray *)friends {
    _friends = friends;
    self.alphabetizedDictionary = [CGLAlphabetizer alphabetizedDictionaryFromObjects:_friends usingKeyPath:@"firstName"];
    self.sectionIndexTitles = [CGLAlphabetizer indexTitlesFromAlphabetizedDictionary:self.alphabetizedDictionary];
    
    [self.tableView reloadData];
}

- (EWPerson *)objectAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionIndexTitle = self.sectionIndexTitles[indexPath.section];
    return self.alphabetizedDictionary[sectionIndexTitle][indexPath.row];
}
#pragma mark - <UITableViewDataSource>

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.sectionIndexTitles;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sectionIndexTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionIndexTitle = self.sectionIndexTitles[section];
    return [self.alphabetizedDictionary[sectionIndexTitle] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWFriendsViewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.friendsTableViewCell forIndexPath:indexPath];
    
    EWPerson *friend = [self objectAtIndexPath:indexPath];
    cell.person = friend;
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewCell *sectionCell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.friendsTableViewCellSectionHeader];
    UILabel *label = (UILabel *)[sectionCell.contentView viewWithTag:kFriendViewCellSectionLabelID];
    label.text = self.sectionIndexTitles[section];
    
    return sectionCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EWPerson *person = [self objectAtIndexPath:indexPath];
    
    EWProfileViewController *vc = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:MainStoryboardIDs.viewControllers.EWProfile];
    vc.person = person;
    [self.navigationController pushViewController:vc animated:YES];
//    EWBaseNavigationController *nav = [[EWBaseNavigationController alloc] initWithRootViewController:vc];
//    [nav setNavigationBarTransparent:YES];
//    @weakify(vc);
//    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"Close" style:UIBarButtonItemStylePlain handler:^(id sender) {
//       @strongify(vc);
//        [vc dismissViewControllerAnimated:YES completion:nil];
//    }];
//    vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"More" style:UIBarButtonItemStylePlain handler:^(id sender) {
//        
//    }];
//    
//    [self presentWithBlur:nav withCompletion:nil];
}
#pragma mark - Status Bar
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
@end
