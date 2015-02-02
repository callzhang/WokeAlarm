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

static const NSArray *socialLevels;
static const NSArray *pref;

@interface EWSettingsViewController () {
    NSString *selectedCellTitle;
    NSArray *ringtoneList;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableDictionary *preference;
@end

@interface RDSelectionViewController()<UIPickerViewDataSource,UIPickerViewDelegate,EWSelectionViewControllerDelegate>
@end

@implementation EWSettingsViewController
@synthesize preference;
@synthesize tableView = _tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.view.backgroundColor = [UIColor clearColor];
    preference = [[EWPerson me].preference mutableCopy]?:[kUserDefaults mutableCopy];
    settingGroup = settingGroupPreference;//legacy code
    ringtoneList = ringtoneNameList;
    socialLevels = @[kSocialLevelFriends, kSocialLevelEveryone];
    pref = @[@"Morning tone", @"Bed time notification", @"Sleep duration", @"Log out", @"About"];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[ImagesCatalog moreButton] style:UIBarButtonItemStylePlain target:self action:@selector(about:)];
    self.navigationItem.leftBarButtonItem = self.mainNavigationController.menuBarButtonItem;
    self.title = @"Preferences";
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[ImagesCatalog wokeBackground]];
    self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.1];
    if ([[UIDevice currentDevice].systemVersion doubleValue]>=7.0f) {
        self.tableView.separatorInset = UIEdgeInsetsZero;// 这样修改，那条线就会占满
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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

@end

@implementation EWSettingsViewController (UITableView)
#pragma mark Cell Maker
- (UITableViewCell *)makeProfileCellInTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"profileCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"profileCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.backgroundColor = kCustomLightGray;
    }
    return cell;
}

- (UITableViewCell *)makePrefCellInTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingPreferenceCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"settingPreferenceCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:1 alpha:0.9];
        cell.backgroundColor = kCustomLightGray;
    }
    return cell;
}

- (UITableViewCell *)makeAboutCellInTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingAboutCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"settingAboutCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.textColor = kCustomGray;
        cell.backgroundColor = kCustomLightGray;
    }
    return cell;
}

#pragma mark - DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (settingGroup) {
        case settingGroupProfile:
            return 8;
            break;
        case settingGroupPreference:
            return pref.count;
            break;
        default: //settingGroupAbout
            return 1;
            break;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    cell= [self makePrefCellInTableView:tableView];
    
    NSString *title = LOCALSTR(pref[indexPath.row]);
    cell.textLabel.text = title;
    if ([title isEqualToString:@"Morning tone"]) {
        NSArray *fileString = [preference[@"DefaultTone"] componentsSeparatedByString:@"."];
        NSString *file = [fileString objectAtIndex:0];
        cell.detailTextLabel.text = file;
    }
    else if ([title isEqualToString:@"Bed time notification"]){
        //switch
        UISwitch *bedTimeNotifSwitch = [[UISwitch alloc] init];
        bedTimeNotifSwitch.tintColor = [UIColor grayColor];
        bedTimeNotifSwitch.onTintColor = [UIColor greenColor];
        bedTimeNotifSwitch.on = (BOOL)preference[@"BedTimeNotification"];
        bedTimeNotifSwitch.tag = 3;
        
        [bedTimeNotifSwitch addTarget:self action:@selector(OnBedTimeNotificationSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = bedTimeNotifSwitch;
    }
    else if ([title isEqualToString:@"Sleep duration"]){
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ hours", preference[@"SleepDuration"]];
    }
    else if ([title isEqualToString:@"Log out"]){
    }
    else if ([title isEqualToString:@"About"]){
    }

    return cell;
}

#pragma mark - Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = pref[indexPath.row];
    selectedCellTitle = title;
    if ([title isEqualToString:@"Morning tone"]){
        RDSelectionViewController *selectionVC = [[RDSelectionViewController alloc] initWithPickerDelegate:self];
        selectionVC.hideNowButton = YES;
        [selectionVC showWithSelectionHandler:^(RDSelectionViewController *vc) {
            NSUInteger row =[vc.picker selectedRowInComponent:0];
            UILabel *titleLabel = (UILabel *)[vc.picker viewForRow:row forComponent:0];
            self.preference[@"DefaultTone"] = titleLabel.text;
            [_tableView reloadData];
            [[EWAVManager sharedManager] stopAllPlaying];
        } andCancelHandler:^(RDSelectionViewController *vc) {
            [[EWAVManager sharedManager] stopAllPlaying];
            DDLogInfo(@"Date selection was canceled (with block)");
        }];
    }
    else if ([title isEqualToString:@"Social"]){//depreciated
        RDSelectionViewController *selectionVC = [[RDSelectionViewController alloc] initWithPickerDelegate:self];
        selectionVC.hideNowButton = YES;
        [selectionVC showWithSelectionHandler:^(RDSelectionViewController *vc) {
            NSUInteger row =[vc.picker selectedRowInComponent:0];
            NSString *level = socialLevels[row];
            self.preference[@"SocialLevel"] = level;
            [_tableView reloadData];
            DDLogInfo(@"Successfully selected date: %ld (With block)",(long)[vc.picker selectedRowInComponent:0]);
       } andCancelHandler:^(RDSelectionViewController *vc) {
           DDLogInfo(@"Date selection was canceled (with block)");
       }];
        
    }
    else if ([title isEqualToString:@"Sleep duration"]){
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
                [_tableView reloadData];
                [[EWAlarmManager sharedInstance] scheduleSleepNotifications];
            }
        } andCancelHandler:^(RDSelectionViewController *vc) {
            DDLogInfo(@"Date selection was canceled (with block)");
        }];
        
    }
    else if ([title isEqualToString:@"Log out"]){
        
        [[[UIAlertView alloc] initWithTitle:@"Log out" message:@"Do you want to log out?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Log out", nil] show];
        
    }
    else if ([title isEqualToString:@"About"]){
        NSString *v = kAppVersion;
        NSString *context = [NSString stringWithFormat:@"Woke \n Version: %@ \n WokeAlarm.com", v];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"About" message:context delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo200"]];
        image.frame = CGRectMake(200, 50, 80, 80);
        [alert addSubview:image];
        [alert show ];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if ([alertView.title isEqualToString:@"Log out"]) {
        if (buttonIndex == 1) {
            [self dismissBlurViewControllerWithCompletionHandler:^{
                //log out
                [[EWAccountManager sharedInstance] logout];
            }];
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
}

@end
@implementation EWSettingsViewController (UIPickView)
#pragma mark - PickDelegate&&DateSource 

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if ([selectedCellTitle isEqualToString:@"Morning tone"]) {
        return ringtoneList.count;
    }
    else if ([selectedCellTitle isEqualToString:@"Sleep duration"]) {
        return sleepDurations.count;
    }
    return 0;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([selectedCellTitle isEqualToString:@"Morning tone"]) {
        NSString *tone = [ringtoneList objectAtIndex:row];
        [EWAVManager.sharedManager playSoundFromFileName:tone];
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, 44)];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
    
    NSString *titleString = @"";
    
    if ([selectedCellTitle isEqualToString:@"Morning tone"]) {
        titleString = ringtoneList[row];
    }
    else if ([selectedCellTitle isEqualToString:@"Sleep duration"]) {
        titleString = [NSString stringWithFormat:@"%@ hours",sleepDurations[row]];
    }
    
    label.text = titleString;
    return label; 
}


@end
