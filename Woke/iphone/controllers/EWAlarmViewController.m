//
//  EWAlarmViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/5/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWAlarmViewController.h"
#import "VBFPopFlatButton.h"

@interface EWAlarmViewController ()

@end

@implementation EWAlarmViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.mainNavigationController.menuBarButtonItem;
    self.title = @"Alarms";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
@end
