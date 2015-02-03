//
//  EWPersonViewController.h
//  EarlyWorm
//
//  Created by Lei on 9/5/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWBaseViewController.h"
#define kMaxPersonNavigationConnt   6

@class EWPerson;
@class EWCachedInfoManager;

@interface EWPersonViewController : EWBaseViewController<UIAlertViewDelegate, UIActionSheetDelegate> 


@property (weak, nonatomic) IBOutlet UIButton *picture;

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *statement;
@property (weak, nonatomic) IBOutlet UILabel *nextAlarm;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIButton *addFriend;
@property (weak, nonatomic) IBOutlet UIButton *wakeBtn;
- (IBAction)photos:(id)sender;
- (IBAction)addFriend:(id)sender;
- (IBAction)wake:(id)sender;

@property (weak, nonatomic) EWPerson *person;

@end
