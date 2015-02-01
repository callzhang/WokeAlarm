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

@interface EWProfileViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation EWProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0f;
    self.title = @"Profile";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"More" style:UIBarButtonItemStylePlain target:self action:@selector(onMoreButton:)];
}

#pragma mark - <UITableViewDataSource>
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        EWProfileViewProfileTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.profileTableViewCellProfile];
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

- (void)onMoreButton:(id)sender {
    
}

#pragma mark -
- (NSArray *)localDataSource {
    static dispatch_once_t onceToken;
    static NSArray *dataSource;
    dispatch_once(&onceToken, ^{
        @weakify(self);
        dataSource = @[
                       @{@"name": @"Friends", @"detail" : ^{
                          return @"xx";
                       }, @"action": ^{
                          @strongify(self);
                           [self performSegueWithIdentifier:MainStoryboardIDs.segues.profileToFriends sender:self];
                       }},
                       @{@"name": ^{
                           //TODO: [Z] return correct phrase, like him, same below
                           return @"People woke her up";
                       }, @"detail": ^{
                          return @"xx";
                       }},
                       @{@"name": ^{
                           return @"People she woke up";
                       }, @"detail": ^{
                          return @"xx";
                       }},
                       @{@"name": @"Last Seen", @"detail": ^{
                          return @"xx";
                       }},
                       @{@"name": @"Wake-ability Score", @"detail": ^{
                          return @"xx";
                       }},
                       ];
    });
    return dataSource;
}
@end
