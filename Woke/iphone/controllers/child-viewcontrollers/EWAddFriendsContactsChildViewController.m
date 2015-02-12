//
//  EWAddFriendsContactsChildViewController.m
//  Woke
//
//  Created by Zitao Xiong on 2/2/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWAddFriendsContactsChildViewController.h"
#import "EWAddFriendsTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "EWSocialManager.h"
#import "EWPerson.h"

@interface EWAddFriendsContactsChildViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, readonly) NSArray *items;
@property (nonatomic, strong) NSDictionary *contactFrinedsOnWoke;
@property (nonatomic, strong) NSDictionary *contactFriends;
@end

@implementation EWAddFriendsContactsChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 70;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items[section][@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWAddFriendsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.addFriendsCell];
    
    NSDictionary *section = self.items[indexPath.section];
    if ([section[@"type"] isEqualToString:@"woke"]) {
        EWPerson *person = section[@"rows"][indexPath.row];
        cell.person = person;
    }
    else if ([section[@"type"] isEqualToString:@"facebook"]) {
        NSDictionary *item = section[@"rows"][indexPath.row];
        cell.nameLabel.text = item[@"name"];
        [cell.profileImageView setImageWithURL:item[@"imageURL"]];
        cell.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        [cell.profileImageView applyHexagonSoftMask];
//        [cell.rightButton setImage:<#(UIImage *)#> forState:<#(UIControlState)#>]; //set invite button
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddFriendsCellSectionHeader"];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    
    if (cell) {
        BOOL isFriendsSection = [self.items[section][@"type"] isEqualToString:@"woke"];
        
        UILabel *sectionLabel = (UILabel *)[cell.contentView viewWithTag:101];
        NSAssert([sectionLabel isKindOfClass:[UILabel class]], @"section label with tag 101 is not a UILabel");
        UIButton *addAllButton = (UIButton *)[cell.contentView viewWithTag:102];
        NSAssert([addAllButton isKindOfClass:[UIButton class]], @"button with tag 102 is not a UIButton");
        if (isFriendsSection) {
            sectionLabel.text = ((NSString* (^)(void))self.contactFrinedsOnWoke[@"sectionName"])();
            addAllButton.hidden = NO;
        }
        else {
            sectionLabel.text = ((NSString* (^)(void))self.contactFriends[@"sectionName"])();
            addAllButton.hidden = YES;
        }
    }
    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (NSArray *)items {
    if (self.contactFriends && self.contactFrinedsOnWoke) {
        return @[self.contactFrinedsOnWoke, self.contactFriends];
    }
    else if (self.contactFriends) {
        return @[self.contactFriends];
    }
    
    
    return nil;
}

- (void)loadFriendsOnWokeSection {
    [[EWSocialManager sharedInstance] findAddressbookUsersFromContactsWithCompletion:^(NSArray *array, NSError *error) {
        if (array.count == 0) {
            return ;
        }
        
        NSDictionary *dictionary = @{@"type": @"woke", @"rows": array,
                                     @"sectionName": ^{
                                         //TODO, 单复数
                                         return [NSString stringWithFormat:@"%@ friend%@ on Woke", @(array.count), array.count>1?@"s":@""];
                                     }, @"showRightButton": @(YES)
                                     };
        self.contactFrinedsOnWoke = dictionary;
        
        [self.tableView reloadData];
    }];
    
    NSMutableDictionary *facebookFriendsDictioanry = [EWPerson mySocialGraph].facebookFriends;
    
    NSMutableArray *facebookFriends = [NSMutableArray array];
    
    [facebookFriendsDictioanry enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [facebookFriends addObject:@{
                                     @"id": key,
                                     @"name": obj,
                                     @"imageURL": [[EWSocialManager sharedInstance] getFacebookProfilePictureURLWithID:key]
                                     }];
    }];
    
    [facebookFriends sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];
    
    NSMutableArray *friendsToRemove = [NSMutableArray array];
    
    NSArray *facebookFriendIDs = [facebookFriends valueForKeyPath:@"name"];
    [self.contactFrinedsOnWoke[@"rows"] enumerateObjectsUsingBlock:^(EWPerson *person, NSUInteger idx, BOOL *stop) {
        NSString *facebookID = person.socialGraph.facebookID;//TODO: change facebook ID retrive
        if ([facebookFriendIDs containsObject:facebookID]) {
            [friendsToRemove addObject:person];
        }
    }];
    
    
    self.contactFriends = @{
                             @"type": @"facebook",
                             @"rows": facebookFriends,
                             @"sectionName": ^{
                                 //TODO, 单复数
                                 return [NSString stringWithFormat:@"invite other %@ friends?", @(facebookFriends.count)];
                             }, @"showRightButton": @(NO)
                             };
    
    [self.tableView reloadData];
}
@end
