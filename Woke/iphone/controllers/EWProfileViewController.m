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

@interface EWProfileViewController ()<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *wakeHerUpButton;
@property (nonatomic, strong) EWCachedInfoManager *statsManager;
@property (nonatomic, strong) NSArray *localDataSource;
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
        }else {
            [self.wakeHerUpButton setTitle:[NSString stringWithFormat:@"Wake %@ Up", person.genderSubjectiveCaseString] forState:UIControlStateNormal];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = [self.mainNavigationController menuBarButtonItem];
    }
    if (!self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[ImagesCatalog moreButton] style:UIBarButtonItemStylePlain target:self action:@selector(more:)];
    }
}


#pragma mark - UI
- (IBAction)close:(id)sender {
    if (self.presentingViewController){
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    }
}

- (IBAction)more:(id)sender {
    UIActionSheet *sheet;
    if (_person.isMe) {
        
        sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Close" destructiveButtonTitle:nil otherButtonTitles:@"Preference",@"Log out", nil];
#ifdef DEBUG
        [sheet addButtonWithTitle:@"Add friend"];
        [sheet addButtonWithTitle:@"Send Voice Greeting"];
#endif
    }else{
        //sheet.destructiveButtonIndex = 0;
        if (_person.friendshipStatus == EWFriendshipStatusFriended) {
            sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Close" destructiveButtonTitle:nil otherButtonTitles:@"Flag", @"Unfriend", @"Send Voice Greeting", @"Friend history", @"Block", nil];
        }else{
            
            sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Close" destructiveButtonTitle:nil otherButtonTitles:@"Add friend", @"Block", nil];
        }
    }
    
    [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

#pragma mark - <UITableViewDataSource>
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        EWProfileViewProfileTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.profileTableViewCellProfile];
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
@end
