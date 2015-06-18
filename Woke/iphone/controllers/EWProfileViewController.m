//
//  EWProfileViewController.m
//  Woke
//
//  Created by Zitao Xiong on 2/1/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWProfileViewController.h"
#import "EWProfileViewProfileTableViewCell.h"
#import "EWProfileViewNormalTableViewCell.h"
#import "EWCachedInfoManager.h"
#import "EWUIUtil.h"
#import "UIViewController+Blur.h"
#import "EWRecordingViewController.h"
#import "UIActionSheet+BlocksKit.h"
#import "EWAccountManager.h"
#import "EWPersonManager.h"

@interface EWProfileViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *wakeHerUpButton;
@property (nonatomic, strong) EWCachedInfoManager *statsManager;
@property (nonatomic, strong) NSArray *localDataSource;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomLayoutConstraint;
@end

@implementation EWProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0f;
    self.title = @"Profile";
    self.statsManager = [EWCachedInfoManager managerForPerson:_person];
    
    @weakify(self);
    [RACObserve(self, person) subscribeNext:^(EWPerson *person) {
        @strongify(self);
        
        if ([person isMe]) {
            self.wakeHerUpButton.hidden = YES;
            self.tableViewBottomLayoutConstraint.constant = 0;
        }else {
            [self.wakeHerUpButton setTitle:[NSString stringWithFormat:@"Wake %@ Up", person.genderSubjectiveCaseString] forState:UIControlStateNormal];
            self.tableViewBottomLayoutConstraint.constant = 80;
        }
    }];
    
    if (!_person.isMe && [_person.updatedAt timeIntervalSinceNow] < -30) {
        [EWUIUtil showWatingHUB];
        [_person refreshInBackgroundWithCompletion:^(NSError *error) {
            [self.tableView reloadData];
            [EWUIUtil dismissHUD];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSParameterAssert(_person);
}


#pragma mark - UI
- (IBAction)more:(id)sender {
    UIActionSheet *sheet;
    if (_person.isMe) {
        
        //sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook profile",@"Log out", nil];
        sheet = [UIActionSheet bk_actionSheetWithTitle:nil];
        [sheet bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [sheet bk_addButtonWithTitle:@"Facebook" handler:^{
            [self openFacebookProfileForPerson:_person];
        }];
        [sheet bk_addButtonWithTitle:@"Log out" handler:^{
            [[EWAccountManager shared] logout];
        }];
        [sheet showInView:self.view];
        
    }else{
        sheet = [UIActionSheet bk_actionSheetWithTitle:nil];
        [sheet bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [sheet bk_addButtonWithTitle:@"Flag" handler:^{
            [EWUIUtil showText:@"Flag not supported yet"];
        }];
        [sheet bk_addButtonWithTitle:@"Facebook" handler:^{
            [self openFacebookProfileForPerson:_person];
        }];
        if (_person.friendshipStatus == EWFriendshipStatusFriended) {
            [sheet bk_addButtonWithTitle:@"Unfriend" handler:^{
                [[EWPersonManager shared] unfriend:_person completion:^(BOOL success, NSError *error) {
                    DDLogDebug(@"Unfriend %@ with error: %@", success?@"YES":@"NO", error);
                    if (success) {
                        [EWUIUtil showSuccessHUBWithString:@"Unfriended"];
                    } else {
                        [EWUIUtil showFailureHUBWithString:@"Unfriend failed"];
                    }
                }];
            }];
        }else{
            [sheet bk_addButtonWithTitle:@"Send friendship request" handler:^{
                [[EWPersonManager shared] requestFriend:_person completion:^(EWFriendshipStatus status, NSError *error) {
                    DDLogDebug(@"Friendship requested %@  error: %@", status == EWFriendshipStatusSent?@"YES":@"NO", error);
                    if (status == EWFriendshipStatusSent) {
                        [EWUIUtil showSuccessHUBWithString:@"Request sent"];
                    } else {
                        [EWUIUtil showFailureHUBWithString:@"Request failed"];
                    }
                }];
            }];
        }
    }
    [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

- (void)openFacebookProfileForPerson:(EWPerson *)person{
    
    if (!person.facebookID) {
        DDLogError(@"Person %@ don't has a facebook ID", person.name);
        return;
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"fb://profile/%@", person.facebookID]];
    BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:url];
    if (!canOpen) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/profile.php?id=%@", person.facebookID]];
    }
    
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)wake:(id)sender {
    EWRecordingViewController *controlelr = [[UIStoryboard defaultStoryboard] instantiateViewControllerWithIdentifier:NSStringFromClass([EWRecordingViewController class])];
	controlelr.person = self.person;
    [self.navigationController pushViewController:controlelr animated:YES];
}

#pragma mark - <UITableViewDataSource>
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        EWProfileViewProfileTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.profileTableViewCellProfile];
        cell.presentingViewController = self;
        cell.person = self.person;
        return cell;
    }
    else {
        EWProfileViewNormalTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.profileTableViewCellNormal];
        NSDictionary *item = [self localDataSource][indexPath.row - 1];
        NSString *title;
        id titleItem = item[@"name"];
        if ([titleItem isKindOfClass:[NSString class]]) {
            title = titleItem;
        }
        else {
            title = ((NSString* (^)(void))titleItem)();
        }
        cell.leftAlignLabel.text = title;
        cell.rightAlignLabel.text = ((NSString * (^)(void))item[@"detail"])();
        void (^ configuration)(EWProfileViewNormalTableViewCell *cell) = item[@"configuration"];
        if (configuration) {
            configuration(cell);
        }
        return cell;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self localDataSource].count + 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > 0) {
        NSDictionary *item = [self localDataSource][indexPath.row - 1];
        id action = item[@"action"];
        if (action) {
            ((void (^)(void))action)();
        }
    }
}

#pragma mark -
- (NSArray *)localDataSource {
    if (!_localDataSource) {
        @weakify(self);
        _localDataSource = @[
                       @{@"name": @"Friends", @"detail" : ^{
                          return [NSString stringWithFormat:@"%@", @(_person.friends.count)];
                       }, @"action": ^{
                          @strongify(self);
                           if ([self.person isMe]) {
                               [self performSegueWithIdentifier:MainStoryboardIDs.segues.profileToFriends sender:self];
                           }
                       }, @"configuration": ^(EWProfileViewNormalTableViewCell *cell) {
                           cell.accessoryView = [[UIImageView alloc] initWithImage:[ImagesCatalog wokeUserProfileDisclosureIndicator]];
                       }},
                       @{@"name": ^{
                           return [NSString stringWithFormat:@"People woke %@ up", _person.genderSubjectiveCaseString];
                       }, @"detail": ^{
                        NSArray *receivedMedias = _person.receivedMedias.allObjects;
                          return [NSString stringWithFormat:@"%@", @(receivedMedias.count)];
                       }},
                       @{@"name": ^{
                           return [NSString stringWithFormat:@"People %@ woke up", _person.genderObjectiveCaseString];
                       }, @"detail": ^{
                           NSArray *medias = _person.sentMedias.allObjects;
                           return [NSString stringWithFormat:@"%@", @(medias.count)];
                       }},
                       @{@"name": @"Last Seen", @"detail": ^{
                          return [NSString stringWithFormat:@"%@ ago", _person.updatedAt.timeElapsedString];
                       }},
                       @{@"name": @"Wake-ability Score", @"detail": ^{
                          return _statsManager.wakabilityStr;
                       }},
                       ];
    }
    
    return _localDataSource;
}
#pragma mark - Status Bar
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
@end
