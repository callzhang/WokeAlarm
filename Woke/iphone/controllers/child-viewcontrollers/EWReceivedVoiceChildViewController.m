//
//  EWReceivedVoiceChildViewController.m
//  Woke
//
//  Created by Zitao Xiong on 2/7/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWReceivedVoiceChildViewController.h"
#import "BlocksKit.h"
#import "EWMedia.h"
#import "EWWakeUpViewCell.h"
#import "EWAVManager.h"
#import "EWWakeUpManager.h"
#import "EWPerson+Woke.h"
#import "EWActivity.h"
#import "TMKit.h"
#import "EWVoiceSectionHeaderRowItem.h"
#import "EWSentVoiceRowItem.h"
#import "NSDate+MTDates.h"

@interface EWReceivedVoiceChildViewController ()<UITableViewDelegate, UITableViewDataSource>
//@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray* items;
@property (nonatomic, weak) EWMedia *playingMedia;
@property (nonatomic, strong) TMTableViewBuilder *tableViewBuilder;
@end

@implementation EWReceivedVoiceChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableViewBuilder = [[TMTableViewBuilder alloc] initWithTableView:self.tableView];
    @weakify(self);
    self.tableViewBuilder.reloadBlock = ^(TMTableViewBuilder *builder) {
        @strongify(self);
        //       outter: {@"date": date, @"items": objectInSameDate}
        //    innter: @{@"date": date, @"media": obj}
        for (EWActivity *item in self.items) {
            TMSectionItem *section = [builder addedSectionItem];
            EWVoiceSectionHeaderRowItem *headerRow = [EWVoiceSectionHeaderRowItem new];
            EWActivity *activity = item;
            NSDate *time = activity.completed;
            headerRow.text = [time mt_stringFromDateWithFormat:@"MMM dd, yyyy" localized:YES];
            headerRow.detailText = [NSString stringWithFormat:@"Woke up at %@", [time mt_stringFromDateWithHourAndMinuteFormat:MTDateHourFormat24Hour]];
            [section addRowItem:headerRow];
            for (EWMedia *innerItem in item.medias) {
                EWSentVoiceRowItem *rowItem = [[EWSentVoiceRowItem alloc] init];
                rowItem.media = innerItem;
                [section addRowItem:rowItem];
                [rowItem setDidSelectRowHandler:^(EWSentVoiceRowItem *rowItem) {
                    EWMedia *targetMedia = rowItem.media;
                    if ([targetMedia isEqual:self.playingMedia] && [EWAVManager sharedManager].isPlaying) {
                        [[EWAVManager sharedManager] stopAllPlaying];
                        self.playingMedia = nil;
                    }
                    else {
                        [[EWAVManager sharedManager] playMedia:targetMedia];
                        self.playingMedia = targetMedia;
                        [EWWakeUpManager sharedInstance].currentMediaIndex = @(rowItem.indexPath.row);
                    }
                }];
            }
        }
    };
    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark -
- (NSArray *)items {
    if (!_items) {
        NSArray *activities = [EWPerson myActivities];
        NSMutableArray *noneEmptyActivies = [NSMutableArray array];
        for (EWActivity *activity in activities) {
            if (activity.medias.count != 0) {
                [noneEmptyActivies addObject:activity];
            }
        }
        _items = noneEmptyActivies;
    }
    
    return _items;
}

@end
