//
//  EWNotificationViewController.h
//  Woke
//
//  Created by Lee on 5/1/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EWNotificationViewController : EWBaseNavigationController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end
