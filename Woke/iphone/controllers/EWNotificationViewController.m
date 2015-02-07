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

@interface EWNotificationViewController (){
    NSArray *notifications;
    UIActivityIndicatorView *loading;
}

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
    loading = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    loading.hidesWhenStopped = YES;
    UIBarButtonItem *refreshBtn = [[UIBarButtonItem alloc] initWithCustomView:loading];
    refreshBtn.action = @selector(refresh:);
    refreshBtn.target = self;
    self.navigationItem.leftBarButtonItem = [self.mainNavigationController menuBarButtonItem];
    self.navigationItem.rightBarButtonItem = refreshBtn;
    
    NSInteger nUnread = notifications.count;
    if (nUnread != 0){
        self.title = [NSString stringWithFormat:@"Notifications (%ld)",(unsigned long)nUnread];
    }
    else{
        self.title = @"Notifications";
    }
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
    [notifications enumerateObjectsUsingBlock:^(EWNotification *noti, NSUInteger idx, BOOL *stop) {
        noti.completed = [NSDate date];
    }];
    
    [mainContext MR_saveToPersistentStoreWithCompletion:nil];
}

- (BOOL)prefersStatusBarHidden{
    return NO;
}

- (void)reload{
    notifications = [EWPerson myNotifications];
    [self.tableView reloadData];
}

#pragma mark - UI event
- (IBAction)close:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)refresh:(id)sender{
    [loading startAnimating];
    
    @weakify(self);
    //TODO: refactor the following notification related call to it's functinal class. 
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([EWNotification class])];
    if ([EWPerson me].notifications.count) {
        [query whereKey:kParseObjectID notContainedIn:[[EWPerson me].notifications valueForKey:kParseObjectID]];
    }
    [query whereKey:EWNotificationRelationships.owner equalTo:[PFUser currentUser]];
    [EWSync findParseObjectInBackgroundWithQuery:query completion:^(NSArray *objects, NSError *error) {
        @strongify(self);
        for (PFObject *PO in objects) {
            EWNotification *notification = (EWNotification *)[PO managedObjectInContext:mainContext];
            DDLogVerbose(@"Found new notification %@(%@)", notification.type, notification.objectId);
            notification.owner = [EWPerson me];
        }
        [self reload];
        
        //[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [loading stopAnimating];
		
		if (notifications.count != 0){
			self.title = [NSString stringWithFormat:@"Notifications (%ld)",(unsigned long)notifications.count];
            [[EWPerson me] save];
		}
    }];
}

#pragma mark - TableView
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:MainStoryboardIDs.reusables.EWNotificationTalbeViewCell];
    
    EWNotification *notification = notifications[indexPath.row];
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
    EWNotification *notice = notifications[indexPath.row];
    [[EWNotificationManager shared] handleNotification:notice.objectId];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return notifications.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        EWNotification *notice = notifications[indexPath.row];
        //remove from view with animation
        [notice remove];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
