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
    self.friends = [EWPerson myFriends];
    
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.sectionIndexColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
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
@end
