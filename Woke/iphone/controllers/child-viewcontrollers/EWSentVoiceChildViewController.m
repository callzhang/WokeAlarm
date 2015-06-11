//
//  EWSentVoiceChildViewController.m
//  Woke
//
//  Created by Zitao Xiong on 2/7/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWSentVoiceChildViewController.h"
#import "BlocksKit.h"
#import "EWMedia.h"
#import "EWWakeUpViewCell.h"
#import "EWVoiceTableViewCell.h"
#import "EWWakeUpManager.h"
#import "EWAVManager.h"
#import "EWActivity.h"
#import "TMKit.h"
#import "EWVoiceRowItem.h"
#import "EWVoiceSectionHeaderRowItem.h"

@interface EWSentVoiceChildViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray* items;
@property (nonatomic, weak) EWMedia *playingMedia;
@property (nonatomic, strong) TMTableViewBuilder *tableViewBuilder;
@end

@implementation EWSentVoiceChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableViewBuilder = [[TMTableViewBuilder alloc] initWithTableView:self.tableView];
    @weakify(self);
    self.tableViewBuilder.reloadBlock = ^(TMTableViewBuilder *builder) {
        @strongify(self);
//       outter: {@"date": date, @"items": objectInSameDate}
//    innter: @{@"date": date, @"media": obj}
        TMSectionItem *section = [builder addedSectionItem];
        for (NSDictionary *item in self.items) {
            EWVoiceSectionHeaderRowItem *headerRow = [EWVoiceSectionHeaderRowItem new];
            headerRow.text = item[@"date"];
            [section addRowItem:headerRow];
            for (NSDictionary *innerItem in item[@"items"]) {
                EWVoiceRowItem *rowItem = [[EWVoiceRowItem alloc] init];
                rowItem.media = innerItem[@"media"];
                [section addRowItem:rowItem];
                [headerRow addRelatedRowItem:rowItem];
                [rowItem setDidSelectRowHandler:^(EWVoiceRowItem *rowItem) {
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
                
                [rowItem setOnDeleteRowHandler:^(EWVoiceRowItem *rowItem) {
                    [rowItem deleteRowWithAnimation:UITableViewRowAnimationFade];
                    [rowItem.media remove];
                    [headerRow removeRelatedRowItem:rowItem];
                }];
            }
        }
    };
    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor clearColor];
}

- (NSArray *)items {
    if (!_items) {
        NSSet *medias = [[EWPerson me] sentMedias];
        NSMutableSet *datesSet = [NSMutableSet set];
        NSSet *map = [medias bk_map:^id(EWMedia *obj) {
            //TODO: use createdAt, but currently it is nil, use updatedAt temporary
            NSString *date = [obj.updatedAt mt_stringFromDateWithFormat:@"MMM dd, yyyy" localized:YES] ? : @"";
            [datesSet addObject:date];
            return @{@"date": date, @"media": obj};
        }];
        
        NSMutableArray *__items = [NSMutableArray array];
        
        for (NSString *date in datesSet) {
            NSMutableArray *objectInSameDate = [NSMutableArray array];
            
            //iterate objects in map, added object has same <date> into <objectInSameDate>
            for (NSDictionary *dict in map) {
                NSString *inDate = dict[@"date"];
                
                if ([inDate isEqualToString:date]) {
                    [objectInSameDate addObject:dict];
                }
            }
            
            [__items addObject:@{@"date": date, @"items": objectInSameDate}];
        }
        
        _items = __items;
    }
    
    return _items;
}
@end
