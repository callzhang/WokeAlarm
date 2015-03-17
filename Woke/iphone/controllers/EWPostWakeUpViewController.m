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
#import "EWSleepingViewController.h"
#import "TTTArrayFormatter.h"
#import "BlocksKit.h"
#import "NSString+InflectorKit.h"


@interface EWPostWakeUpViewController()<UITableViewDataSource, UITableViewDelegate, EWBaseViewNavigationBarButtonsDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableviewHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *tableViewHeaderLabel;
@end

@implementation EWPostWakeUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableviewHeaderView.backgroundColor = [UIColor clearColor];
    if ([EWWakeUpManager shared].canSnooze) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(onBack:)];
    }
    else {
        DDLogInfo(@"Snooze disabled, hide back button");
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMedias) name:kNewMediaNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kAVManagerDidStartPlaying object:nil queue:nil usingBlock:^(NSNotification *note) {
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            EWMedia *media = note.object;
            [self scrollToMedia:media];
        }else{
            static id observer;
            observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note) {
                DDLogVerbose(@"application did enter foreground, start move to playing cell");
                [self scrollToPlayingMedia];
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
            }];
        }
    }];
    
    [self updateHeaderLabel];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [EWUIUtil applyAlphaGradientForView:_tableView withEndPoints:@[@0.1, @0.8]];
}

- (void)updateHeaderLabel {
    NSArray *lists = [[self medias] bk_map:^id(EWMedia *media) {
        return media.author.name;
    }];
    TTTArrayFormatter *formatter = [[TTTArrayFormatter alloc] init];
    [formatter setUsesAbbreviatedConjunction:NO];
    [formatter setUsesSerialDelimiter:NO];
    NSString *target = @"message";
    if (lists.count == 1) {
        target = [target singularizedString];
    }
    else {
        target = [target pluralizedString];
    }
    self.tableViewHeaderLabel.text = [NSString stringWithFormat:@"%@ sent you wake up %@.", [formatter stringFromArray:lists], target];
}

- (void)reloadMedias{
    [self.tableView reloadData];
    [self updateHeaderLabel];
}

#pragma mark - <UITableViewDataSource>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self medias].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWWakeUpViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EWWakeUpViewCell"];
    cell.media = [self medias][indexPath.row];
    [cell.image applyHexagonSoftMask];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EWMedia *targetMedia = [self medias][indexPath.row];
    if ([targetMedia isEqual:[EWWakeUpManager sharedInstance].currentMedia] && [EWAVManager sharedManager].isPlaying) {
        [[EWAVManager sharedManager] stopAllPlaying];
    }
    else {
        [[EWAVManager sharedManager] playMedia:targetMedia];
        [EWWakeUpManager sharedInstance].currentMediaIndex = @(indexPath.row);
    }
}

#pragma mark - properties
- (NSArray *)medias {
    return [EWWakeUpManager sharedInstance].medias;
}

#pragma mark - UI Actions
- (IBAction)done:(id)sender {
	if (self.presentingViewController) {
		[[EWWakeUpManager sharedInstance] stopPlayingVoice];
		[[EWWakeUpManager sharedInstance] wake:nil];
        [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:nil];
    }
}

- (void)onBack:(id)sender {
    [self performSegueWithIdentifier:MainStoryboardIDs.segues.postWakeupUnwindToSleeping sender:self];
}

- (IBAction)snooze:(id)sender{
    BOOL canSnooze = [EWWakeUpManager shared].canSnooze;
    if (!canSnooze) {
        [EWUIUtil showWarningHUBWithString:@"No snooze!"];
    }else {
        DDLogInfo(@"===> Snooze");
        [[EWWakeUpManager sharedInstance] sleep:nil];
    }
}

- (void)scrollToPlayingMedia{
    EWMedia *m = [EWWakeUpManager shared].currentMedia;
    [self scrollToMedia:m];
}

- (void)scrollToMedia:(EWMedia *)media{
    NSUInteger index = [self.medias indexOfObject:media];
    if (index != NSNotFound && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

#pragma mark - Delegate
- (IBAction)close:(id)sender{
    [self snooze:sender];
}

@end
