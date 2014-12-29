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
}
@end


@implementation EWPreWakeViewController
- (void)viewDidLoad{
    [super viewDidLoad];
    
    //data source
    [[EWWakeUpManager sharedInstance] playNextVoice];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kNewMediaNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if (note.object == [EWPerson myCurrentAlarmActivity]) {
            [self updateViewForCurrentMedia];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kAVManagerDidStartPlaying object:nil queue:nil usingBlock:^(NSNotification *note) {
        
        [self updateViewForCurrentMedia];
        //[[EWAVManager sharedManager] playMedia:self.currentMedia];
    }];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationItem.leftBarButtonItem = [self.mainNavigationController menuBarButtonItem];
    
    //update view
    [self updateViewForCurrentMedia];
    
    //update progress
    progressUpdateTimer = [NSTimer bk_scheduledTimerWithTimeInterval:.1 block:^(NSTimer *timer) {
        if ([EWAVManager sharedManager].player.isPlaying) {
            if (self.progress.alpha == 0) {
                [UIView animateWithDuration:0.5 animations:^{
                    self.progress.alpha = 1;
                }];
            }
            float t = [EWAVManager sharedManager].player.currentTime;
            float d = [EWAVManager sharedManager].player.duration;
            self.progress.progress = t / d;
        }else{
            if (self.progress.alpha == 1) {
                [UIView animateWithDuration:0.5 animations:^{
                    self.progress.alpha = 0;
                }];
            }
        }
    } repeats:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [progressUpdateTimer invalidate];
}


#pragma mark - UI
- (void)updateViewForCurrentMedia{
    EWPerson *author = [EWWakeUpManager sharedInstance].currentMedia.author;
    self.profileImage.image = author.profilePic;
    self.name.text = author.name;
}

- (IBAction)wakeUp:(UIButton *)sender {
    DDLogInfo(@"Wake button pressed!");
    [[EWWakeUpManager sharedInstance] wake];
}

- (IBAction)newMedia:(id)sender {
    //call server test function
    [PFCloud callFunctionInBackground:@"testSendWakeUpVoice" withParameters:@{kParseObjectID: [EWPerson me].objectId} block:^(id object, NSError *error) {
        //
        if (!error) {
            DDLogInfo(@"Finished test voice request");
            //check new media
            NSArray *newMedias = [[EWMediaManager sharedInstance] checkUnreadMedias];
            if (newMedias.count) {
                //update view
                DDLogVerbose(@"New media found (%ld)", newMedias.count);
                
            }
        }else{
            DDLogError(@"Failed test voice request: %@", error.description);
        }
    }];
}

- (IBAction)next:(id)sender {
    [[EWWakeUpManager sharedInstance] playNextVoice];
}
@end
