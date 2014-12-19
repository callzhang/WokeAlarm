//
//  EWPreWakeViewController.m
//  Woke
//
//  Created by Lee on 12/9/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWPreWakeViewController.h"
#import "EWSession.h"
#import "EWWakeUpManager.h"
#import "EWMedia.h"
#import "EWActivity.h"
#import "EWAVManager.h"
#import "NSTimer+BlocksKit.h"
#import "EWAVManager.h"
#import "EWMediaManager.h"
#import "EWAlarm.h"

@interface EWPreWakeViewController(){
    NSTimer *progressUpdateTimer;
}

@end

@implementation EWPreWakeViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    //add unread media to current activity
    EWActivity *currentActivity = [EWWakeUpManager sharedInstance].currentActivity;
    EWAlarm *nextAlarm = [EWPerson myCurrentAlarm];
    for (EWMedia *media in [EWPerson me].unreadMedias) {
        if (!media.targetDate || [media.targetDate timeIntervalSinceDate:nextAlarm.time.nextOccurTime]<0) {
            [currentActivity addMediasObject:media];
        }
    }
    //remove media from unreadMedias
    for (EWMedia *media in currentActivity.medias) {
        [[EWPerson me] addUnreadMediasObject:media];
    }
    self.medias = currentActivity.medias.allObjects;
    self.currentMedia = self.medias.firstObject;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //update view
    [self updateViewForCurrentMedia];
    
    //update progress
    progressUpdateTimer = [NSTimer bk_scheduledTimerWithTimeInterval:0.05 block:^(NSTimer *timer) {
        if ([EWAVManager sharedManager].player.isPlaying) {
            if (self.progress.alpha < 1) {
                [UIView animateWithDuration:0.5 animations:^{
                    self.progress.alpha = 1;
                }];
            }
            float t = [EWAVManager sharedManager].player.currentTime;
            float d = [EWAVManager sharedManager].player.duration;
            self.progress.progress = t / d;
        }else{
            if (self.progress.alpha >0) {
                [UIView animateWithDuration:0.5 animations:^{
                    self.progress.alpha = 0;
                }];
            }
        }
        
    } repeats:YES];
    
    //register playing info
    [[NSNotificationCenter defaultCenter] addObserverForName:kAudioPlayerPlayingNewMedia object:nil queue:nil usingBlock:^(NSNotification *note) {
        //update info
        [self updateViewForCurrentMedia];
    }];
    
    self.navigationItem.leftBarButtonItem = [self.mainNavigationController menuBarButtonItem];
}

- (void)dealloc{
    [progressUpdateTimer invalidate];
}


#pragma mark - UI

- (void)refresh{
    if (!self.currentMedia) {
        self.currentMedia = self.medias.firstObject;
    }
    [self updateViewForCurrentMedia];
}

- (void)updateViewForCurrentMedia{
    self.profileImage.image = self.currentMedia.author.profilePic;
    self.name.text = self.currentMedia.author.name;
}

- (IBAction)wakeUp:(UIButton *)sender {
    DDLogInfo(@"Wake button pressed!");
}

- (IBAction)newMedia:(id)sender {
    //call server test function
    [PFCloud callFunctionInBackground:@"testSendWakeUpVoice" withParameters:@{kParseObjectID: [EWPerson me].objectId} block:^(id object, NSError *error) {
        //
        if (!error) {
            DDLogInfo(@"Finished test voice request");
            //check new media
            BOOL newMedia = [[EWMediaManager sharedInstance] checkMediaAssets];
            if (newMedia) {
                //update view
                DDLogVerbose(@"New media found");
                [self refresh];
            }
        }else{
            DDLogError(@"Failed test voice request: %@", error.description);
        }
    }];
}
@end
