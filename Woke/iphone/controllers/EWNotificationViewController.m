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
#import "EWBaseViewController.h"

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
    
    //notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:kNotificationCompleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:kNotificationNew object:nil];
    
    // Data source
    notifications = [EWPerson myNotifications];
    
    //tableview
    self.tableView.delegate = self;
    self.tableView.dataSource =self;
    self.tableView.contentInset = UIEdgeInsetsMake(2, 0, 200, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.1];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    //[EWUIUtil applyAlphaGradientForView:self.tableView withEndPoints:@[@0.13]];
    UINib *nib = [UINib nibWithNibName:@"EWNotificationCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kNotificationCellIdentifier];
    
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
    if ([EWSession sharedSession].currentUser.isOutDated) {
        [self refresh:nil];
    }
}

- (BOOL)prefersStatusBarHidden{
    return YES;
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
    
    PFQuery *query = [PFQuery queryWithClassName:@"EWNotification"];
    [query whereKey:kParseObjectID notContainedIn:[[EWSession sharedSession].currentUser.notifications valueForKey:kParseObjectID]];
    [query whereKey:@"owner" equalTo:[PFUser currentUser]];
    [EWSync findServerObjectInBackgroundWithQuery:query completion:^(NSArray *objects, NSError *error) {
        for (PFObject *PO in objects) {
            EWNotification *notification = (EWNotification *)[PO managedObjectInContext:mainContext];
            NSLog(@"Found new notification %@(%@)", notification.type, notification.objectId);
            notification.owner = [EWSession sharedSession].currentUser;
        }
        notifications = [EWPerson myUnreadNotifications];
        [self.tableView reloadData];
        
        //[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [loading stopAnimating];
		
		if (notifications.count != 0){
			self.title = [NSString stringWithFormat:@"Notifications (%ld)",(unsigned long)notifications.count];
		}
    }];
}

#pragma mark - TableView
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:kNotificationCellIdentifier];
    
    EWNotification *notification = notifications[indexPath.row];
    if (cell.notification != notification) {
        cell.notification = notification;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWNotification *notification = notifications[indexPath.row];
    NSString *type = notification.type;
    if ([type isEqualToString:kNotificationTypeSystemNotice]) {
        EWNotificationCell *cell = (EWNotificationCell*)[self tableView:self.tableView cellForRowAtIndexPath:indexPath];
        return cell.height;
    }
    else {
        return 70;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EWNotification *notice = notifications[indexPath.row];
    [[EWNotificationManager shared] handleNotification:notice.objectId];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return notifications.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0];
}

//-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
//    view.backgroundColor = [UIColor clearColor];
//    return view;
//}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        EWNotification *notice = notifications[indexPath.row];
        //remove from view with animation
        [notice remove];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
