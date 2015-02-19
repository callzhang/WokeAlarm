//
//  EWPostWakeUpViewController.m
//  Woke
//
//  Created by Zitao Xiong on 1/13/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWPostWakeUpViewController.h"
#import "EWWakeUpManager.h"
#import "EWWakeUpViewCell.h"
#import "EWAVManager.h"
#import "UIViewController+Blur.h"
#import "EWUIUtil.h"
@interface EWPostWakeUpViewController()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableviewHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *tableViewHeaderLabel;
@end

@implementation EWPostWakeUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableviewHeaderView.backgroundColor = [UIColor clearColor];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [EWUIUtil applyAlphaGradientForView:_tableView withEndPoints:@[@0.1, @0.8]];
}

#pragma mark - <UITableViewDataSource>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self medias].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWWakeUpViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EWWakeUpViewCell"];
    cell.media = [self medias][indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EWMedia *targetMedia = [self medias][indexPath.row];
    if ([targetMedia isEqual:[EWWakeUpManager sharedInstance].currentMedia] && [EWAVManager sharedManager].isPlaying) {
        [[EWAVManager sharedManager] stopAllPlaying];
    }
    else {
        [[EWAVManager sharedManager] playMedia:targetMedia];
        [EWWakeUpManager sharedInstance].currentMediaIndex = indexPath.row;
    }
}

#pragma mark - properties
- (NSArray *)medias {
    return [EWWakeUpManager sharedInstance].medias;
}

#pragma mark - UI Actions
- (IBAction)done:(id)sender {
    if (self.presentingViewController) {
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:^{
            [[EWWakeUpManager sharedInstance] stopPlayingVoice];
            [[EWWakeUpManager sharedInstance] wake:nil];
        }];
    }
}
@end
