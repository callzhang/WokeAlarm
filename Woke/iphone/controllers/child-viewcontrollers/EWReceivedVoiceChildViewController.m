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

@interface EWReceivedVoiceChildViewController ()<UITableViewDelegate, UITableViewDataSource>
//@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray* items;
@property (nonatomic, weak) EWMedia *playingMedia;

@end

@implementation EWReceivedVoiceChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = 70;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark - <TableView>
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWWakeUpViewCell *cell = (EWWakeUpViewCell *) [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.EWWakeUpViewCell];
    
    cell.media = [self objectInItemsAtIndexPath:indexPath][@"media"];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items[section][@"items"] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.EWWakeUpViewCellSectionHeader];
    NSDictionary *sectionItem = self.items[section];
    
    UILabel *leftLabel = (UILabel *)[cell.contentView viewWithTag:101];
    NSAssert([leftLabel isKindOfClass:[UILabel class]], @"left label is not a UILabel");
    UILabel *rightLabel = (UILabel *)[cell.contentView viewWithTag:102];
    NSAssert([rightLabel isKindOfClass:[UILabel class]], @"right label is not a UILabel");
    
    leftLabel.text = sectionItem[@"date"];
    rightLabel.text = @"TBD";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EWMedia *targetMedia = [self objectInItemsAtIndexPath:indexPath][@"media"];
    if ([targetMedia isEqual:self.playingMedia] && [EWAVManager sharedManager].isPlaying) {
        [[EWAVManager sharedManager] stopAllPlaying];
        self.playingMedia = nil;
    }
    else {
        [[EWAVManager sharedManager] playMedia:targetMedia];
        self.playingMedia = targetMedia;
        [EWWakeUpManager sharedInstance].currentMediaIndex = @(indexPath.row);
    }
}

#pragma mark -
- (NSArray *)items {
    if (!_items) {
        NSSet *medias = [[EWPerson me] receivedMedias];
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

- (NSDictionary *)objectInItemsAtIndexPath:(NSIndexPath *)indexPath {
    return [self.items[indexPath.section][@"items"] objectAtIndex:indexPath.row];
}
@end
