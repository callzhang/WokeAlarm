//
//  EWSettingsViewController.h
//  EarlyWorm
//
//  Created by shenslu on 13-7-28.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWPerson.h"
#import "EWRingtoneSelectionViewController.h"
#import "EWBaseTableViewController.h"

typedef enum {
    settingGroupProfile,
    settingGroupPreference,
    settingGroupAbout
} settingGroupList;

@interface EWSettingsViewController : EWBaseTableViewController <EWRingtoneSelectionDelegate, UIAlertViewDelegate> {
    settingGroupList settingGroup;
    NSString *cellIdentifier;
    //preference
    EWRingtoneSelectionViewController *ringtoneVC;
}

@end
