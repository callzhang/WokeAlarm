//
//  EWProfileViewProfileTableViewCell.m
//  Woke
//
//  Created by Zitao Xiong on 2/1/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWProfileViewProfileTableViewCell.h"
#import "EWPerson.h"
#import "EWAlarmManager.h"
#import "APTimeZones.h"
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
        //pic
        [self.profileImageButton setImage:person.profilePic forState:UIControlStateNormal];
        [self.profileImageButton applyHexagonSoftMask];
        //name
        self.nameLabel.text = person.name;
        //statement
        self.statementLabel.text = person.statement;
        //location
        if (person.city) {
            self.locationLabel.text =[NSString stringWithFormat:@"%@ | ",person.city];
        }else{
            self.locationLabel.text = @"";
        }
        //location
        self.distanceLabel.text = person.distanceString;
        
        if (person.isMe) {
            self.addFriendButton.hidden = YES;
        }else{
            if (person.isFriend) {
                [self.addFriendButton setImage:[ImagesCatalog friendedIcon] forState:UIControlStateNormal];
            }else if (person.friendWaiting){
                [self.addFriendButton setTitle:@"Waiting" forState:UIControlStateNormal];
                //[self.addFriendButton setImage:[ImagesCatalog addFriendButton] forState:UIControlStateNormal];
            }else if(person.friendPending){
                [self.addFriendButton setImage:[ImagesCatalog addFriendButton] forState:UIControlStateNormal];
                self.addFriendButton.alpha = 0.2;
            }else{
                [self.addFriendButton setImage:[ImagesCatalog addFriendButton] forState:UIControlStateNormal];
            }
        }
    }];
    
    [RACObserve(self, showGlobalTime) subscribeNext:^(NSNumber *showGlobalTime) {
        @strongify(self);
        //TODO: [Zitao] person missing
        NSDate *time = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:_person];
        if (showGlobalTime.boolValue) {
            if (_person.location) {
                NSTimeZone *userTimezone = [[APTimeZones sharedInstance] timeZoneWithLocation:_person.location];
                NSDate *userTime = [time mt_inTimeZone:userTimezone];
                NSString *timeString = [NSString stringWithFormat:@"Next Alarm: %@ (%@)", userTime.date2detailDateString, userTimezone.abbreviation];
                [self.nextAlarmButton setTitle:timeString forState:UIControlStateNormal];
            }else{
                [self.nextAlarmButton setTitle:[NSString stringWithFormat:@"Next Alarm: %@", time.date2detailDateString] forState:UIControlStateNormal];
            }
        }
        else {
            [self.nextAlarmButton setTitle:[NSString stringWithFormat:@"Next Alarm: %@", time.date2detailDateString] forState:UIControlStateNormal];
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
