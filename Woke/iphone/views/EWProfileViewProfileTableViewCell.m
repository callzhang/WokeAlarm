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

- (void)setNextAlarmTimeWithMode:(NSNumber *)showGlobalTime {
    if (!_person) {
        return;
    }
    
    NSDate *time = [[EWAlarmManager sharedInstance] nextAlarmTimeForPerson:_person];
//    NSAssert(time, @"time for person:%@ is nil", _person);
    
    if (showGlobalTime.boolValue) {
        if (_person.location) {
            NSTimeZone *userTimezone = [[APTimeZones sharedInstance] timeZoneWithLocation:_person.location];
            NSDate *userTime = [time mt_inTimeZone:userTimezone];
            NSAssert(time, @"userTime is nil");
            NSAssert(userTimezone, @"timeZone is nil");
            NSAssert(userTime.date2detailDateString, @"userTime.date2detailDateString is nil");
            NSString *timeString = [NSString stringWithFormat:@"Next Alarm: %@ (%@)", userTime.date2detailDateString, userTimezone.abbreviation];
            [self.nextAlarmButton setTitle:timeString forState:UIControlStateNormal];
        }
        else{
            [self.nextAlarmButton setTitle:[NSString stringWithFormat:@"Next Alarm: %@", time.date2detailDateString] forState:UIControlStateNormal];
        }
    }
    else {
        [self.nextAlarmButton setTitle:[NSString stringWithFormat:@"Next Alarm: %@", time.date2detailDateString] forState:UIControlStateNormal];
    }
}

- (IBAction)onAddFriendButton:(id)sender {
    EWFriendshipStatus status = _person.friendshipStatus;
    if ([self.person isMe]) {
        DDLogError(@"do nothing");
    }
    else if(status == EWFriendshipStatusFriended) {
       UIAlertController *controller =  [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Unfriend" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[EWPerson me] unfriend:self.person];
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        
        [controller addAction:action];
        [controller addAction:cancel];
        [[[UIWindow mainWindow] rootNavigationController] presentViewController:controller animated:YES
                                                                     completion:nil];
    }
    else if (status == EWFriendshipStatusSent) {
        UIAlertController *controller =  [UIAlertController alertControllerWithTitle:@"Friendship pending" message:@"You have already requested friendship to this person." preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }];
        
        [controller addAction:action];
        [[[UIWindow mainWindow] rootNavigationController] presentViewController:controller animated:YES completion:nil];
    }
    else {
        [[EWPerson me] requestFriend:self.person];
    }
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
        }
        else{
            self.locationLabel.text = @"";
        }
        //location
        self.distanceLabel.text = person.distanceString;
        
        if (person.isMe) {
            self.addFriendButton.hidden = YES;
        }
        else{
            
            self.addFriendButton.hidden = NO;
            self.addFriendButton.alpha = 1.0f;
            switch (person.friendshipStatus) {
                case EWFriendshipStatusFriended:
                    [self.addFriendButton setImage:[ImagesCatalog friendedIcon] forState:UIControlStateNormal];
                    break;
                case EWFriendshipStatusSent:
                    [self.addFriendButton setImage:[ImagesCatalog friendedIcon] forState:UIControlStateNormal];
                    break;
                case EWFriendshipStatusReceived:
                    [self.addFriendButton setImage:[ImagesCatalog friendedIcon] forState:UIControlStateNormal];
                    break;
                default:
                    [self.addFriendButton setImage:[ImagesCatalog addFriendButton] forState:UIControlStateNormal];
                    break;
 
            }
        }
        
        [self setNextAlarmTimeWithMode:@(self.showGlobalTime)];
    }];
    
    [RACObserve(self, showGlobalTime) subscribeNext:^(NSNumber *showGlobalTime) {
        @strongify(self);
        [self setNextAlarmTimeWithMode:showGlobalTime];
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
