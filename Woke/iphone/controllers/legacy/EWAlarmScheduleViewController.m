//
//  EWAlarmScheduleViewController.m
//  EarlyWorm
//
//  Created by Lei on 10/18/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAlarmScheduleViewController.h"
#import "EWAlarmManager.h"
#import "EWAlarm.h"
#import "EWAlarmEditCell.h"
#import "EWPersonManager.h"
#import "UIViewController+Blur.h"

//Util
#import "EWUIUtil.h"

//backend
#import "EWStartUpSequence.h"
//#import "EWCostumTextField.h"
#import "UIView+Extend.h"

static NSString *cellIdentifier = @"scheduleAlarmCell";

@implementation EWAlarmScheduleViewController{
    NSInteger selected;
    NSArray *alarms;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    //tableview
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 240, 0);
    UINib *cellNib = [UINib nibWithNibName:@"EWAlarmEditCell" bundle:nil];
    [_tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
    
    //alpha mask
    [EWUIUtil applyAlphaGradientForView:self.tableView withEndPoints:@[@0.15]];
    
    //header view
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Confirm Button"] style:UIBarButtonItemStylePlain target:self action:@selector(onDone)];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Close Button"] style:UIBarButtonItemStylePlain target:self action:@selector(OnCancel)];
	//[EWUIUtil addTransparantNavigationBarToViewController:self];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    self.title = @"Schedule Alarms";
    
    //data
    [self initData];
    
    //add alarm observer
    [[EWAlarmManager sharedInstance] addObserver:self forKeyPath:@"isSchedulingAlarm" options:NSKeyValueObservingOptionNew context:nil];
    [[EWPerson me] addObserver:self forKeyPath:EWPersonRelationships.alarms options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if ([EWAlarmManager sharedInstance].isSchedulingAlarms) {
        [self.view showLoopingWithTimeout:0];
    }
}

- (void)dealloc{
    @try {
        [[EWAlarmManager sharedInstance] removeObserver:self forKeyPath:@"isSchedulingAlarm"];
        [[EWPerson me] removeObserver:self forKeyPath:@"alarms"];
    }
    @catch (NSException *exception) {
        DDLogError(@"Failed to remove observer: %@", exception.description);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([object isKindOfClass:[EWAlarmManager class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([keyPath isEqualToString:@"isSchedulingAlarm"]) {
                if (![EWSession sharedSession].isSchedulingAlarm) {
                    DDLogInfo(@"Schedule view detected alarm finished scheduling");
                    [EWUIUtil dismissHUD];
                    [self initData];
                    
                }else{
                    DDLogInfo(@"Schedule View detect alarm schedule");
                    [self.view showLoopingWithTimeout:0];
                }
            }
        });
        
    }else if (object == [EWPerson me]){
        [EWUIUtil dismissHUD];
        [self initData];
        [self.view showLoopingWithTimeout:0];
    }
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)initData{
    //data source
    alarms = [EWPerson myAlarms];
    selected = 99;
    [self.tableView reloadData];
}

- (void)save{
    [self.view showLoopingWithTimeout:0];
    
    BOOL hasChanges = NO;
    
    
    for (NSUInteger i=0; i < alarms.count; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
        EWAlarmEditCell *cell = (EWAlarmEditCell *)[_tableView cellForRowAtIndexPath:path];
        if (!cell ) {
            cell = (EWAlarmEditCell *)[self tableView:_tableView cellForRowAtIndexPath:path];
        }
        
        EWAlarm *alarm = cell.alarm;
        if (!alarm) {
            DDLogError(@"*** Getting cell that has no alarm, skip");
            continue;
        }
        //state
        if (cell.alarmToggle.selected != alarm.stateValue) {
            NSLog(@"Change alarm state for %@ to %@", alarm.time.mt_stringFromDateWithFullWeekdayTitle, cell.alarmToggle.selected?@"ON":@"OFF");
            alarm.stateValue = cell.alarmToggle.selected?YES:NO;
            //[[NSNotificationCenter defaultCenter] postNotificationName:kAlarmStateChangedNotification object:alarm userInfo:@{@"alarm": alarm}];
            hasChanges = YES;
        }

        //time
        if (cell.myTime && ![cell.myTime isEqualToDate:alarm.time]) {
            
            DDLogVerbose(@"Time updated to %@", [cell.myTime date2detailDateString]);
            alarm.time = cell.myTime;
			//task.time = cell.myTime;
			//x[[NSNotificationCenter defaultCenter] postNotificationName:kAlarmTimeChangedNotification object:alarm userInfo:@{@"alarm": alarm}];
            hasChanges = YES;
        }
        
        //statement
        if (cell.statement.text.length && ![cell.statement.text isEqualToString:alarm.statement]) {
            NSString *statement = [NSString stringWithFormat:@"%@", cell.statement.text];
            alarm.statement = statement;
            hasChanges = YES;
        }
    }
    
	if (hasChanges) {
		//save
    }
    
    [EWUIUtil dismissHUD];
}

#pragma mark - UI events
- (void)onDone{
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
    [self save];
}

- (void)OnCancel{
    [self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item{
    
    return YES;
}


#pragma mark - tableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return alarms.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //reusable cell
    EWAlarmEditCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    //data
    if (!cell.alarm) {
        EWAlarm *alarm = alarms[indexPath.row];
        cell.alarm = alarm;
    }
    
    //breaking MVC pattern to get ringtonVC work
    cell.presentingViewController = self;
    
    //return
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    //CGFloat alpha = indexPath.row%2?0.05:0.06;
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	// If our cell is selected, return double height
	if(selected == indexPath.row    ) {
		return 130.0;
	}
	
	// Cell isn't selected so return single height
	return 80.0;
}

//when click one item in table, push view to detail page
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
//    EWAlarmEditCell * cell =(EWAlarmEditCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
//    if (!cell.alarmToggle.selected) {
//        return;
//    }
    [UIView animateWithDuration:0.01 animations:^{
           [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }];
    
    [tableView beginUpdates];
    
    //highlight the seleted cell
 
    
    
    
    if (selected == indexPath.row) {
        selected = 99;
    }else{
        selected = indexPath.row;
    }
    
    
    [tableView endUpdates];
}


- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:selected inSection:0];
    EWAlarmEditCell *cell = (EWAlarmEditCell *)[self.tableView cellForRowAtIndexPath:path];
    [cell hideKeyboard:cell.statement];
}



@end
