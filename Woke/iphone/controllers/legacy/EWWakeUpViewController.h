//
//  WakeUpViewController.h
//  EarlyWorm
//
//  Created by Lei Zhang on 7/28/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//
#import "EWBaseTableViewController.h"
#import <UIKit/UIKit.h>
@class EWPerson, EWMedia, EWAlarm, EWMediaCell;

@interface EWWakeUpViewController : EWBaseTableViewController// <UIPopoverControllerDelegate>
//@property (weak, nonatomic) IBOutlet UILabel *title;
//@property (weak, nonatomic) IBOutlet UILabel *timer;
//@property (weak, nonatomic) IBOutlet UILabel *AM;
//@property (weak, nonatomic) IBOutlet UIView *header;
//@property (weak, nonatomic) IBOutlet UILabel *seconds;
//@property (weak, nonatomic) IBOutlet UIView *footer;
//@property (weak, nonatomic) IBOutlet UIButton *wakeupButton;
//@property (strong, nonatomic) IBOutlet UILabel *timeDescription;
//@property (strong, nonatomic) IBOutlet EWShakeProgressView *shakeProgress;
//@property (nonatomic, strong) EWMediaCell *currentCell;

@property (nonatomic, weak) EWPerson *person;
@property (nonatomic, weak) EWActivity *activity;
- (IBAction)finish:(id)sender;


/**
 Search for cell that has media that has the audioKey that metches the playing URL in EWAVManager.
 Returns the index of current playing cell.
 */
//- (NSInteger)seekCurrentCell;
@end
