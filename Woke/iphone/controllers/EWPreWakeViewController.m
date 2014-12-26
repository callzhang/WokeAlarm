//
//  EWPreWakeViewController.m
//  Woke
//
//  Created by Lee on 12/9/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWPreWakeViewController.h"
#import "EWWakeUpManager.h"
#import "EWMedia.h"
#import "EWAVManager.h"
#import "NSTimer+BlocksKit.h"
#import "EWAlarm.h"
#import "EWMediaManager.h"

@interface EWPreWakeViewController(){
    NSTimer *progressUpdateTimer;
    //NSUInteger currentPlayCount;
}

@end

@implementation EWPreWakeViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    //data source
    [self refresh];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kNewMediaNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if (note.object == [EWPerson myCurrentAlarmActivity]) {
            [self refresh];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kAudioPlayerDidFinishPlaying object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSUInteger currentPlayCount = [self.medias indexOfObjectIdenticalTo:self.currentMedia]+1;
        if (currentPlayCount >= self.medias.count) {
            currentPlayCount = 0;
        }
        self.currentMedia = self.medias[currentPlayCount];
        [self refresh];
        [[EWAVManager sharedManager] playMedia:self.currentMedia];
    }];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //update view
    [self updateViewForCurrentMedia];
    
    //update progress
    progressUpdateTimer = [NSTimer bk_scheduledTimerWithTimeInterval:.1 block:^(NSTimer *timer) {
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

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [progressUpdateTimer invalidate];
}


#pragma mark - UI

- (void)refresh{
    self.medias = [EWPerson myUnreadMedias];
    if (!self.currentMedia) {
        self.currentMedia = self.medias.firstObject;
        [[EWAVManager sharedManager] playMedia:self.currentMedia];
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
            }
        }else{
            DDLogError(@"Failed test voice request: %@", error.description);
        }
    }];
}
@end
