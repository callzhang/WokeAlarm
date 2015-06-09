//
//  EWNotificationViewController.m
//  Woke
//
//  Created by Lee on 5/1/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWNotificationViewController.h"
#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWUIUtil.h"

#import "EWNotificationCell.h"
#import "UIView+Layout.h"

#define kNotificationCellIdentifier     @"NotificationCellIdentifier"

@interface EWNotificationViewController ()
@property (nonatomic, strong) NSArray *notifications;
@property (nonatomic, strong) UIActivityIndicatorView *loading;
@end

@implementation EWNotificationViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //TODO: [ZhangLei] name refactor!!!
    //notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:kNotificationCompleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:kNotificationNew object:nil];
    
    // Data source
    [self reload];
    
    //tableview
    //toolbar
    _loading = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    _loading.hidesWhenStopped = YES;
    UIBarButtonItem *refreshBtn = [[UIBarButtonItem alloc] initWithCustomView:_loading];
    refreshBtn.action = @selector(refresh:);
    refreshBtn.target = self;
    //self.navigationItem.leftBarButtonItem = [self.mainNavigationController menuBarButtonItem];
    self.navigationItem.rightBarButtonItem = refreshBtn;
    
    @weakify(self);
    [RACObserve(self, notifications) subscribeNext:^(NSArray *notifications) {
        @strongify(self);
        NSInteger nUnread = notifications.count;
        if (nUnread != 0){
            self.title = [NSString stringWithFormat:@"Notifications (%ld)",(unsigned long)nUnread];
        }
        else{
            self.title = @"Notifications";
        }
    }];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //refresh
    [self refresh:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.notifications enumerateObjectsUsingBlock:^(EWNotification *noti, NSUInteger idx, BOOL *stop) {
		if (!noti.completed) {
			noti.completed = [NSDate date];
		}
    }];
    
    [mainContext MR_saveToPersistentStoreWithCompletion:nil];
}

- (BOOL)prefersStatusBarHidden{
    return NO;
}

- (void)reload{
    self.notifications = [EWPerson myNotifications];
    [self.tableView reloadData];
}

#pragma mark - UI event
- (IBAction)close:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)refresh:(id)sender{
    if ([EWPerson me].isOutDated) {
        [_loading startAnimating];
        [[EWNotificationManager shared] findAllNotificationInBackgroundwithCompletion:^(NSArray *array, NSError *error) {
            
            //notifications = array.mutableCopy;
            [_loading stopAnimating];
            [self reload];
        }];
    }
}

#pragma mark - TableView
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.EWNotificationTalbeViewCell];
    
    EWNotification *notification = _notifications[indexPath.row];
    cell.notification = notification;
    
    if (indexPath.row % 2) {
        cell.contentView.backgroundColor = [UIColor clearColor];
    }
    else {
        cell.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.04];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EWNotification *notice = _notifications[indexPath.row];
    [[EWNotificationManager shared] notificationDidClicked:notice];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _notifications.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        EWNotification *notice = _notifications[indexPath.row];
        //remove from view with animation
        NSUInteger nNotification = _notifications.count;
        [notice remove];
		self.notifications = [EWPerson myNotifications];
        NSParameterAssert(nNotification == (_notifications.count+1));
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Status Bar
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
@end
