//
//  EWAlarmToneViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/13/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWAlarmToneViewController.h"
#import "EWAVManager.h"

@implementation EWAlarmToneViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor clearColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        self.checkMark.hidden = NO;
    }
    else {
        self.checkMark.hidden = YES;
    }
}
@end

@interface EWAlarmToneViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSString *currentTone;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation EWAlarmToneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.items = [EWSession sharedSession].alarmTones;
    self.currentTone = [EWSession sharedSession].currentAlarmTone;
   
    self.title = @"Choose Alarm";
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:nil action:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSUInteger index = [self.items indexOfObject:self.currentTone];
    if (index == NSNotFound) {
        index = 0;
    }
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[EWAVManager sharedManager] stopAllPlaying];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWAlarmToneViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EWAlarmToneViewCell"];
    
    cell.alarmLabel.text = self.items[indexPath.row];
    
    if ([cell.alarmLabel.text isEqualToString:self.currentTone]) {
        cell.selected = YES;
    }
    else {
        cell.selected = NO;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.currentTone = self.items[indexPath.row];
    [EWSession sharedSession].currentAlarmTone = self.currentTone;
    
    [[EWAVManager sharedManager] playSoundFromURL:[[NSBundle mainBundle] URLForResource:self.currentTone withExtension:@"caf"]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //    DDLogInfo(@"%@ : insets: %@", NSStringFromCGPoint(scrollView.contentOffset), NSStringFromUIEdgeInsets(scrollView.scrollIndicatorInsets));
//    float offset = scrollView.scrollIndicatorInsets.top + scrollView.contentOffset.y;
//    if (offset > 0) {
//        [self.mainNavigationController setNavigationBarTransparent:NO];
//    }
//    else {
//        [self.mainNavigationController setNavigationBarTransparent:YES];
//    }
}
@end
