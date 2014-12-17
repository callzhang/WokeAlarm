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

@interface EWPreWakeViewController(){
    NSTimer *progressUpdateTimer;
}

@end

@implementation EWPreWakeViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.medias = [EWWakeUpManager sharedInstance].currentActivity.medias.allObjects;
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

//UI
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
        }else{
            DDLogError(@"Failed test voice request: %@", error.description);
        }
    }];
}
@end
