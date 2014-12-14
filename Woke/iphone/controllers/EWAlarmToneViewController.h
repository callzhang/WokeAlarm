//
//  EWAlarmToneViewController.h
//  Woke
//
//  Created by Zitao Xiong on 12/13/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWBaseTableViewController.h"

@interface EWAlarmToneViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *alarmLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkMark;

@end

@interface EWAlarmToneViewController : EWBaseTableViewController

@end
