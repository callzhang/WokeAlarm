//
//  EWPostWakeUpViewController.m
//  Woke
//
//  Created by Zitao Xiong on 1/13/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWPostWakeUpViewController.h"
#import "EWWakeUpManager.h"
#import "EWWakeUpViewCell.h"
@interface EWPostWakeUpViewController()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation EWPostWakeUpViewController

#pragma mark - <UITableViewDataSource>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self medias].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EWWakeUpViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EWWakeUpViewCell"];
    cell.media = [self medias][indexPath.row];
    return cell;
}

#pragma mark - properties
- (NSArray *)medias {
    return [EWWakeUpManager sharedInstance].medias;
}
@end
