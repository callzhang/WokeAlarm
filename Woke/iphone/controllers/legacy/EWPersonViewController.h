//
//  EWPersonViewController.h
//  EarlyWorm
//
//  Created by Lei on 9/5/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EWPerson;
@class EWCachedInfoManager;

@interface EWPersonViewController : UIViewController<UIAlertViewDelegate, UIActionSheetDelegate> {
    //NSArray *tasks;
    EWCachedInfoManager *stats;
    NSArray *profileItemsArray;
}
//@property (assign,nonatomic)BOOL canSeeFriendsDetail;
@property (strong, nonatomic) IBOutlet UIButton *addFriendButton;
//PersonInfoView
@property (weak, nonatomic) IBOutlet UIButton *picture;
- (IBAction)photos:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *statement;
@property (weak, nonatomic) IBOutlet UILabel *nextAlarm;
//@property (weak, nonatomic) IBOutlet UISegmentedControl *tabView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addFriend;
@property (weak, nonatomic) EWPerson *person;


//- (EWPersonViewController *)initWithPerson:(EWPerson *)person;
//- (void)refresh;

@end
