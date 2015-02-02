//
//  EWProfileViewProfileTableViewCell.m
//  Woke
//
//  Created by Zitao Xiong on 2/1/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWProfileViewProfileTableViewCell.h"
#import "EWPerson.h"
@interface EWProfileViewProfileTableViewCell()
@property (nonatomic, strong) RACDisposable *personDisposable;
@property (nonatomic, assign) BOOL showGlobalTime;
@end

@implementation EWProfileViewProfileTableViewCell

- (void)awakeFromNib {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self racBind];
}

- (void)prepareForReuse {
    [self racBind];
}

- (void)racBind {
    [self.personDisposable dispose];
    
    @weakify(self);
    self.personDisposable = [RACObserve(self, person) subscribeNext:^(EWPerson *person) {
        @strongify(self);
        [self.profileImageButton setImage:person.profilePic forState:UIControlStateNormal];
        [self.profileImageButton applyHexagonSoftMask];
        self.nameLabel.text = person.name;
        //TODO:// change discription
        self.locationLabel.text = [person.location description];
        self.statementLabel.text = person.statement;
    }];
    
    [RACObserve(self, showGlobalTime) subscribeNext:^(NSNumber *showGlobalTime) {
        @strongify(self);
        if (showGlobalTime.boolValue) {
            //TODO:[ZHANG]
            [self.nextAlarmButton setTitle:@"show global time" forState:UIControlStateNormal];
        }
        else {
            [self.nextAlarmButton setTitle:@"show local alarm time" forState:UIControlStateNormal];
        }
    }];
    
}

- (IBAction)onNextAlarmButton:(id)sender {
    if (self.showGlobalTime) {
        self.showGlobalTime = NO;
    }
    else {
        self.showGlobalTime = YES;
    }
}
@end
