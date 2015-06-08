//
//  EWAddFriendsFacebookChildViewController.m
//  Woke
//
//  Created by Zitao Xiong on 2/2/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWAddFriendsFacebookChildViewController.h"
#import "EWSocialManager.h"
#import "EWAddFriendTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "EWPersonManager.h"

@interface EWAddFriendsFacebookChildViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, readonly) NSArray *items;
@property (nonatomic, strong) NSDictionary *facebookFrinedsOnWoke;
//@property (nonatomic, strong) NSDictionary *facebookFriends;
@end

@implementation EWAddFriendsFacebookChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"EWAddFriendTableViewCell" bundle:nil] forCellReuseIdentifier:@"EWAddFriendTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"EWAddFriendsSectionTableViewCell" bundle:nil] forCellReuseIdentifier:@"AddFriendsCellSectionHeader"];
    [self loadFriendsOnWokeSection];
    self.tableView.rowHeight = 70;
    self.tableView.sectionHeaderHeight = 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return self.items.count;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return [self.items[section][@"rows"] count];
    if (self.items.count == 1) {
        return [[self.items[0] valueForKey:@"rows"] count] + 1;
    }
    else if (self.items.count == 2){
        return [[self.items[0] valueForKey:@"rows"] count] + 1 + [[self.items[1] valueForKey:@"rows"] integerValue] + 1;
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isHeaderSection:indexPath]) {
        NSInteger section = 0;
        if (indexPath.row == (NSInteger)[[self.items[0] valueForKey:@"rows"] count] + 1) {
            section = 1;
        }
        
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
                sectionLabel.text = ((NSString* (^)(void))self.facebookFrinedsOnWoke[@"sectionName"])();
                addAllButton.hidden = NO;
            }
            else {
                //            sectionLabel.text = ((NSString* (^)(void))self.facebookFriends[@"sectionName"])();
                //            addAllButton.hidden = YES;
            }
            
            [addAllButton removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
            [addAllButton addTarget:self action:@selector(onAddAllButton) forControlEvents:UIControlEventTouchUpInside];
            
        }
        
        return cell;
    }
    indexPath = [self convertSingleIndexPathToCombineIndexPath:indexPath];
    
    EWAddFriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EWAddFriendTableViewCell"];
    
    NSDictionary *section = self.items[indexPath.section];
    if ([section[@"type"] isEqualToString:@"woke"]) {
        EWPerson *person = section[@"rows"][indexPath.row];
        cell.person = person;
    }
    else {
        DDLogError(@"not supported");
    }
    
    return cell;
}

- (NSIndexPath *)convertSingleIndexPathToCombineIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    if (row > (NSInteger) [[self.items[0] valueForKey:@"rows"] count]+ 1) {
        return [NSIndexPath indexPathForRow:row - [[self.items[0] valueForKey:@"rows"] count] - 1 - 1 inSection:1];
    }
    else if ([self isHeaderSection:indexPath]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"indexPath is a header" userInfo:nil];
    }
    else {
        return [NSIndexPath indexPathForRow:row - 1 inSection:0];
    }
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddFriendsCellSectionHeader"];
//    cell.contentView.backgroundColor = [UIColor clearColor];
//    cell.backgroundColor = [UIColor clearColor];
//    
//    if (cell) {
//        BOOL isFriendsSection = [self.items[section][@"type"] isEqualToString:@"woke"];
//        
//        UILabel *sectionLabel = (UILabel *)[cell.contentView viewWithTag:101];
//        NSAssert([sectionLabel isKindOfClass:[UILabel class]], @"section label with tag 101 is not a UILabel");
//        UIButton *addAllButton = (UIButton *)[cell.contentView viewWithTag:102];
//        NSAssert([addAllButton isKindOfClass:[UIButton class]], @"button with tag 102 is not a UIButton");
//        
//        if (isFriendsSection) {
//            sectionLabel.text = ((NSString* (^)(void))self.facebookFrinedsOnWoke[@"sectionName"])();
//            addAllButton.hidden = NO;
//        }
//        else {
////            sectionLabel.text = ((NSString* (^)(void))self.facebookFriends[@"sectionName"])();
////            addAllButton.hidden = YES;
//        }
//        
//        [addAllButton removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
//        [addAllButton addTarget:self action:@selector(onAddAllButton) forControlEvents:UIControlEventTouchUpInside];
//
//    }
//    
//    return cell;
//}

- (BOOL)isHeaderSection:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 && indexPath.section == 0) {
        return YES;
    }
    else if (indexPath.row == (NSInteger)[[self.items[0] valueForKey:@"rows"] count] + 1) {
        return YES;
    }
    else {
        return NO;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isHeaderSection:indexPath]) {
        return 30;
    }
    else {
        return 70;
    }
}
- (void)onAddAllButton {
    NSArray *rows = self.items.firstObject[@"rows"];
    for (EWPerson *person in rows) {
        if (person.friendshipStatus == EWFriendshipStatusNone) {
            [[EWPersonManager shared] requestFriend:person completion:^(EWFriendshipStatus status, NSError *error) {
                DDLogVerbose(@"friend request sent, status changed to :%@", @(status));
                if (error) {
                    DDLogError(@"got friend request sending error:%@", error);
                }
            }];
        }
    }
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 44;
//}

- (NSArray *)items {
    if (self.facebookFrinedsOnWoke) {
        return @[self.facebookFrinedsOnWoke];
    }
    
    return nil;
}

- (void)loadFriendsOnWokeSection {
    [[EWSocialManager sharedInstance] findNotFriendedFacebookFriendsWithCompletion:^(NSArray *array, NSError *error) {
        if (array.count == 0) {
            return ;
        }
        
        NSDictionary *dictionary = @{@"type": @"woke", @"rows": array,
                                     @"sectionName": ^{
                                         //TODO, 单复数
                                         return [NSString stringWithFormat:@"%@ friends on Woke", @(array.count)];
                                     }, @"showRightButton": @(YES)
                                     };
        self.facebookFrinedsOnWoke = dictionary;
        
        [self.tableView reloadData];
    }];
}

//- (void)loadLocalFriends {
//    NSMutableDictionary *facebookFriendsDictioanry = [EWPerson mySocialGraph].facebookFriends;
//    
//    NSMutableArray *facebookFriends = [NSMutableArray array];
//    
//    [facebookFriendsDictioanry enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//        [facebookFriends addObject:@{
//                                     @"id": key,
//                                     @"name": obj,
//                                     @"imageURL": [[EWSocialManager sharedInstance] getFacebookProfilePictureURLWithID:key]
//                                     }];
//    }];
//    
//    [facebookFriends sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];
//    
//    NSMutableArray *friendsToRemove = [NSMutableArray array];
//    
//    NSArray *facebookFriendIDs = [facebookFriends valueForKeyPath:@"id"];
//    [self.facebookFrinedsOnWoke[@"rows"] enumerateObjectsUsingBlock:^(EWPerson *person, NSUInteger idx, BOOL *stop) {
//        NSString *facebookID = person.socialGraph.facebookID;//TODO: change facebook ID retrive
//        if ([facebookFriendIDs containsObject:facebookID]) {
//           [facebookFriends enumerateObjectsUsingBlock:^(NSDictionary *dic, NSUInteger idx, BOOL *stop) {
//               if ([dic[@"id"] isEqualToString:facebookID]) {
//                   [friendsToRemove addObject:dic];
//               }
//           }];
//        }
//    }];
//    
//    [facebookFriends removeObjectsInArray:friendsToRemove];
//    
//    self.facebookFriends = @{
//                             @"type": @"facebook",
//                             @"rows": facebookFriends,
//                             @"sectionName": ^{
//                                 //TODO, 单复数
//                                 return [NSString stringWithFormat:@"invite other %@ friends?", @(facebookFriends.count)];
//                             }, @"showRightButton": @(NO)
//                             };
//    
//    [self.tableView reloadData];
//}
@end
