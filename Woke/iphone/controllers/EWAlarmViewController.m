//
//  EWAlarmViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/5/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWAlarmViewController.h"
#import "VBFPopFlatButton.h"
#import "EWAlarmTableViewCell.h"
#import "EWAlarm.h"

#define kToneLabelTag 99

@interface EWAlarmViewController ()
@property (nonatomic, strong) NSArray *alarms;

@end

@implementation EWAlarmViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.mainNavigationController.menuBarButtonItem;
    self.title = @"Alarms";
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"woke-background"]];
    
    self.alarms = [EWPerson myAlarms];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    
    if (section == 1) {
        return self.alarms.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 20;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 20)];
    footer.backgroundColor = [UIColor clearColor];
    return footer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *toneCell = [tableView dequeueReusableCellWithIdentifier:@"EWAlarmToneSelectionCell"];
        toneCell.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.04];
        return toneCell;
    }
    
    EWAlarmTableViewCell *cell = (EWAlarmTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"EWAlarmTableViewCell"];
    
    if (indexPath.row % 2 == 0) {
        cell.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.02];
    }
    else {
        cell.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.04];
    }
    
    EWAlarm *alarm = self.alarms[indexPath.row];
    cell.mondayLabel.text = alarm.time.mt_stringFromDateWithFullWeekdayTitle;
    cell.timeLabel.text = [alarm.time mt_stringFromDateWithFormat:@"hh:mm a" localized:YES];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 60;
    }
    
    if (indexPath.section == 1) {
        return 80;
    }
    
    return 0;
}
@end
