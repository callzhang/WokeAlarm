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
#import "RHPerson.h"
#import "RHAddressBook.h"
#import "BlocksKit.h"

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadLocalContactFriends];
    [self loadFriendsOnWokeSection];
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
    if ([section[@"type"] isEqualToString:@"address-book"]) {
        cell.type = EWAddFreindTableViewCellTypeInvite;
        
        RHPerson *person = section[@"rows"][indexPath.row];
        if (person.thumbnail) {
            cell.profileImageView.image = person.thumbnail;
        }
        else {
            //NOTE: only male here
            cell.profileImageView.image = [ImagesCatalog wokePlaceholderUserProfileImageMale];
        }
        
        [cell.rightButton removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
        NSString *name = person.name ? : @"";
        cell.nameLabel.text = name;
        @weakify(self);
        cell.onInviteBlock = ^{
            @strongify(self);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invite" message:[NSString stringWithFormat:@"Invite %@ to woke?", name] preferredStyle:UIAlertControllerStyleActionSheet];
            //add email
            for (NSString *email in person.emails.values) {
                if (!email) continue;
                UIAlertAction *action = [UIAlertAction actionWithTitle:email style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    //TODO: email
                    DDLogInfo(@"show action");
                }];
                [alert addAction:action];
            }
            
            //add phone
            for (NSString *phone in person.phoneNumbers.values) {
                UIAlertAction *action = [UIAlertAction actionWithTitle:phone style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    //TODO: phone
                    DDLogInfo(@"show action");
                }];
                [alert addAction:action];
            }
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        };
    }
    else if ([section[@"type"] isEqualToString:@"woke"]) {
        cell.type = EWAddFreindTableViewCellTypeAddFriend;
        
        NSDictionary *item = section[@"rows"][indexPath.row];
        cell.nameLabel.text = item[@"name"];
        UIImage *image = item[@"image"];
        if (image) {
            cell.profileImageView.image = image;
        }
        else {
            cell.profileImageView.image = [ImagesCatalog wokePlaceholderUserProfileImageMale];
        }
    }

    cell.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    
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
    [[EWSocialManager sharedInstance] findAddressbookUsersInWokeWithCompletion:^(NSArray *array, NSError *error) {
        if (array.count == 0) {
            return ;
        }
        NSArray *addressBookFriendsInWoke = [EWPerson mySocialGraph].addressBookRelatedUsers ? : @[];
        
        self.contactFrinedsOnWoke = @{
                                      @"type": @"woke",
                                      //            @{@"email": email, @"name": contact.name, @"image": thumbnail}
                                      @"rows": addressBookFriendsInWoke,
                                      @"sectionName": ^{
                                          //TODO, 单复数
                                          return [NSString stringWithFormat:@"invite other %@ friends?", @(addressBookFriendsInWoke.count)];
                                      }, @"showRightButton": @(NO)
                                      };
        
        [self loadLocalContactFriends];
        
        [self.tableView reloadData];
    }];
}

- (void)loadLocalContactFriends {
    if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusNotDetermined) {
        [[[RHAddressBook alloc] init] requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
            [self loadLocalContactFriends];
            return;
        }];
    }
    else {
        NSArray *people = [EWSocialManager sharedInstance].addressPeople;
        self.contactFriends = @{
                                @"type": @"address-book",
                                @"rows": people,
                                @"sectionName": ^{
                                    return [NSString stringWithFormat:@"invite other %@ friend%@?", @(people.count), people.count > 1 ? @"s":@""];
                                }, @"showRightButton": @(NO)
                                };
        [self.tableView reloadData];
    }
}
@end
