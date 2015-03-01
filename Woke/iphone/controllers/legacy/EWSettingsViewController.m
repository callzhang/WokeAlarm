//
//  EWSettingsViewController.m
//  EarlyWorm
//
//  Created by shenslu on 13-7-28.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "EWSettingsViewController.h"
#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWMediaCell.h"
#import "EWFirstTimeViewController.h"
#import "EWLogInViewController.h"

#import "RDSelectionViewController.h"
#import "RMDateSelectionViewController.h"
#import "EWAVManager.h"
#import "EWAlarmManager.h"
#import "UIViewController+Blur.h"
#import "NSString+Extend.h"
#import "EWAccountManager.h"
#import "EWSettingsTableViewCell.h"
#import "EXTKeyPathCoding.h"

@interface EWSettingsViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) NSMutableDictionary *preference;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, readonly) NSArray *items;
@end

@interface RDSelectionViewController()<UIPickerViewDataSource,UIPickerViewDelegate,EWSelectionViewControllerDelegate>
@end

@implementation EWSettingsViewController
@synthesize preference;

- (void)viewDidLoad {
    [super viewDidLoad];
    preference = [[EWPerson me].preference mutableCopy]?:[kUserDefaults mutableCopy];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[ImagesCatalog moreButton] style:UIBarButtonItemStylePlain target:self action:@selector(about:)];
    self.navigationItem.leftBarButtonItem = self.mainNavigationController.menuBarButtonItem;
    self.title = @"Preferences";
    self.tableView.backgroundColor = [UIColor clearColor];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [EWPerson me].preference = [preference copy];
    [[EWPerson me] save];
}

#pragma mark - IBAction
- (IBAction)about:(id)sender{
    DDLogInfo(@"About tapped");
}

#pragma mark - RingtongSelectionDelegate
- (void)ViewController:(EWRingtoneSelectionViewController *)controller didFinishSelectRingtone:(NSString *)tone{
    //set ringtone
    preference[@"DefaultTone"] = tone;
    [EWPerson me].preference = preference;
    [[EWPerson me] save];
}

#pragma mark - TableViewDataSource
- (NSArray *)items {
    return @[
             @{
                 @"identifier": MainStoryboardIDs.reusables.settingTableViewCell,
                 @"type": @(EWSettingsTableViewCellTypeSwitch),
                 @"text": @"Bedtime Reminder",
                 @"configuration": ^(EWSettingsTableViewCell *cell){
                     BOOL isOn = (BOOL)preference[@"BedTimeNotification"];
                     [cell.sevenSwitch setOn:isOn animated:NO];
                     [cell.sevenSwitch removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
                     [cell.sevenSwitch addTarget:self action:@selector(OnBedTimeNotificationSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                 },
                 @"backgroundColor": [UIColor colorWithWhite:1.0 alpha:0.04]
                 },
             @{
                @"identifier": MainStoryboardIDs.reusables.settingTableViewSeparatorCell
                 },
//             @{
//                @"type": @(EWSettingsTableViewCellTypeDetail),
//                @"text": @"Time"
//                 },
             @{
                 @"identifier": MainStoryboardIDs.reusables.settingTableViewCell,
                 @"type": @(EWSettingsTableViewCellTypeDetail),
                 @"text": @"Sleep Duration",
                 @"backgroundColor": [UIColor colorWithWhite:1.0 alpha:0.02],
                 @"detailTextBlock": ^{
                     return [NSString stringWithFormat:@"%@ hours", preference[@"SleepDuration"]];
                 },
                 @"action": ^{
                     RDSelectionViewController *selectionVC = [[RDSelectionViewController alloc] initWithPickerDelegate:self];
                     selectionVC.hideNowButton = YES;
                     
                     [selectionVC showWithSelectionHandler:^(RDSelectionViewController *vc) {
                         NSUInteger row =[vc.picker selectedRowInComponent:0];
                         
                         float d = [(NSNumber *)sleepDurations[row] floatValue];
                         float d0 = [(NSNumber *)preference[kSleepDuration] floatValue];
                         if (d != d0) {
                             DDLogInfo(@"Sleep duration changed from %f to %f", d0, d);
                             preference[kSleepDuration] = @(d);
                             [EWPerson me].preference = preference.copy;
                             [self.tableView reloadData];
                             [[EWAlarmManager sharedInstance] scheduleSleepNotifications];
                         }
                     } andCancelHandler:^(RDSelectionViewController *vc) {
                         DDLogInfo(@"Date selection was canceled (with block)");
                     }];
                 }
                 },
             @{
                @"identifier": MainStoryboardIDs.reusables.settingTableViewSeparatorCell
                 },
             @{
                 @"identifier": MainStoryboardIDs.reusables.settingTableViewCell,
                 @"type": @(EWSettingsTableViewCellTypeStandard),
                 @"text": @"About",
                 @"backgroundColor": [UIColor colorWithWhite:1.0 alpha:0.04],
                 @"action": ^{
                     NSString *v = kAppVersion;
                     NSString *context = [NSString stringWithFormat:@"Woke \n Version: %@ \n WokeAlarm.com", v];
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"About" message:context delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                     UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo200"]];
                     image.frame = CGRectMake(200, 50, 80, 80);
                     [alert addSubview:image];
                     [alert show ];
                 }
                 }
             ];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.items[indexPath.row];
    NSString *identifier = item[@"identifier"];
    
    if ([identifier isEqualToString:MainStoryboardIDs.reusables.settingTableViewSeparatorCell]) {
        return 20;
    }
    else if ([identifier isEqualToString:MainStoryboardIDs.reusables.settingTableViewCell]) {
        return 60;
    }
    else {
        DDLogError(@"identifier: %@ not supported", identifier);
        return 60;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.items[indexPath.row];
    NSString *identifier = item[@"identifier"];
    
    UITableViewCell *dequeCell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if ([dequeCell isKindOfClass:[EWSettingsTableViewCell class]]) {
        EWSettingsTableViewCell *cell = (EWSettingsTableViewCell *)dequeCell;
        
        cell.leftLabel.text = item[@"text"];
        EWSettingsTableViewCellType type = [item[@"type"] integerValue];
        cell.type = type;
        
        NSString * (^textBlock)(void) = item[@"detailTextBlock"];
        if (textBlock) {
            cell.rightLabel.text = textBlock();
        }
        
        void (^configuration)(EWSettingsTableViewCell *cell) = item[@"configuration"];
        if (configuration) {
            configuration(cell);
        }
        
        cell.backgroundColor = item[@"backgroundColor"];
        
        return cell;
    }
    //cell is a separator cell
    else {
        return dequeCell;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id action = self.items[indexPath.row][@"action"];
    if (action) {
        ((void (^)(void))action)();
    }
}

- (void)OnBedTimeNotificationSwitchChanged:(UISwitch *)sender{
    [preference setObject:@(sender.on) forKey:kBedTimeNotification];
    [EWPerson me].preference = preference.copy;
    [[EWPerson me] save];
    
    //schedule sleep notification
    if (sender.on == YES) {
        [[EWAlarmManager sharedInstance] scheduleSleepNotifications];
    }
    else{
        [[EWAlarmManager sharedInstance] cancelSleepNotifications];
    }
}

#pragma mark - Picker
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return sleepDurations.count;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, 44)];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
    
    NSString *titleString = @"";
    
    titleString = [NSString stringWithFormat:@"%@ hours",sleepDurations[row]];
    label.text = titleString;
    return label; 
}


@end
