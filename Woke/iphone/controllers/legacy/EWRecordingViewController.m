//
//  EWRecordingViewController.m
//  EarlyWorm
//
//  Created by Lei on 12/24/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWRecordingViewController.h"
//#import "EWAppDelegate.h"

//UI
#import "NSDate+Extend.h"
#import "SCSiriWaveformView.h"
#import "EWUIUtil.h"
#import "UAProgressView.h"

//model
#import "ATConnect.h"
#import "EWMediaFile.h"
#import "EWMedia.h"
#import "EWMediaManager.h"
#import "EWPerson.h"
#import "EWPersonManager.h"
#import "EWAVManager.h"
#import "EWAlarmManager.h"
#import "EWBackgroundingManager.h"
#import "EWServer.h"
#import "UIViewController+Blur.h"

typedef NS_ENUM(NSUInteger, EWRecordingViewState) {
    EWRecordingViewStateInitial,
    EWRecordingViewStateRecording,
    EWRecordingViewStateRecorded,
    EWRecordingViewStatePlaying,
};

@interface EWRecordingViewController ()<EWBaseViewNavigationBarButtonsDelegate>{
    NSURL *recordingFileUrl;
    CADisplayLink *displayLink;
}

@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *retakeButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (nonatomic, assign) EWRecordingViewState state;

@end

@implementation EWRecordingViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    [self initProgressView];
    
    NSParameterAssert(self.person);
    
    //texts
    self.title = @"Recording";

    //NavigationController
    if (!self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = [self.mainNavigationController menuBarButtonItem];
    }

    //waveform
    [self.waveformView setWaveColor:[UIColor colorWithWhite:1.0 alpha:0.75]];
    [self.waveformView updateWithLevel:0.0f];
    
    self.state = EWRecordingViewStateInitial;
}

- (void)setState:(EWRecordingViewState)state {
    _state = state;
    
    self.recordButton.hidden = YES;
    self.retakeButton.hidden = YES;
    self.playButton.hidden = YES;
    self.sendButton.hidden = YES;
    self.stopButton.hidden = YES;
    
    switch (state) {
        case EWRecordingViewStateInitial: {
            self.recordButton.hidden = NO;
            displayLink.paused = YES;
            break;
        }
        case EWRecordingViewStatePlaying: {
            self.stopButton.hidden = NO;
            displayLink.paused = NO;
            break;
        }
        case EWRecordingViewStateRecorded: {
            self.playButton.hidden = NO;
            self.retakeButton.hidden = NO;
            self.sendButton.hidden = NO;
            displayLink.paused = YES;
            break;
        }
        case EWRecordingViewStateRecording: {
            self.stopButton.hidden = NO;
            displayLink.paused = NO;
            break;
        }
            
        default:
            break;
    }
}

-(void)initProgressView{
    self.progressView.tintColor = [UIColor whiteColor];
    self.progressView.borderWidth = 0.0;
    self.progressView.lineWidth = 1;
    
    UILabel *textLabel = (UILabel *)[self.view viewWithTag:30];
    self.progressView.centralView = textLabel;
    
    self.progressView.progressChangedBlock = ^(UAProgressView *progressView, float progress){
        if ([EWAVManager sharedManager].recorder.isRecording) {
            [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%.0f", [EWAVManager sharedManager].recorder.currentTime]];
        }
        
        if ([EWAVManager sharedManager].player.isPlaying) {
            [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%.0f", [EWAVManager sharedManager].player.currentTime]];
        }
    };
    
    //progress views and display link
    self.progressView.progress = 0;
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress:)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    displayLink.paused = YES;
    
    //listen to finish notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopUpdatingProgress:) name:kAVManagerDidFinishPlaying object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopUpdatingProgress:) name:kAVManagerDidFinishRecording object:nil];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[EWAVManager sharedManager] registerRecordingAudioSession];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [[EWBackgroundingManager sharedInstance] registerBackgroudingAudioSession];
}

#pragma mark- Actions
- (IBAction)onPlayButton:(id)sender {
    if (!recordingFileUrl){
        DDLogError(@"Recording url empty");
        return;
    }
    
    //play
    [[EWAVManager sharedManager] playSoundFromURL:recordingFileUrl];
    
    self.state = EWRecordingViewStatePlaying;
}

- (IBAction)onRetakeButton:(id)sender {
    recordingFileUrl = [[EWAVManager sharedManager] record];
    
    self.state = EWRecordingViewStateRecording;
}

- (IBAction)onRecordButton:(id)sender {
    recordingFileUrl = [[EWAVManager sharedManager] record];
    
    self.state = EWRecordingViewStateRecording;
}

- (IBAction)onStopButton:(id)sender {
    [[EWAVManager sharedManager].recorder stop];
    [[EWAVManager sharedManager] stopAllPlaying];
    
    self.state = EWRecordingViewStateRecorded;
}

- (IBAction)onSendButton:(id)sender {
    if (recordingFileUrl) {
        [self.view showLoopingWithTimeout:0];
        
        //finished recording, prepare for data
        NSError *err;
        NSData *recordData = [NSData dataWithContentsOfFile:[recordingFileUrl path] options:0 error:&err];
        if (!recordData) {
            DDLogWarn(@"No recorded file found");
            return;
        }
        
        //save data to task
        [self.view showLoopingWithTimeout:0];
        
        [[ATConnect sharedConnection] engage:kRecordVoiceSuccess fromViewController:self];
        
        EWMediaFile *mediaFile = [EWMediaFile newMediaFile];
        mediaFile.audio = recordData;
        mediaFile.owner = [EWPerson me].serverID;
        
        EWPerson *receiver = self.person;
        
        EWMedia *media = [EWMedia newMedia];
        media.type = kMediaTypeVoice;
        //media.message = self.message.text;
        
        //Add to media queue instead of task
        media.receiver = receiver;
        media.mediaFile = mediaFile;
        media.author = [EWPerson me];
        
        [EWServer pushVoice:media toUser:receiver withCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                DDLogError(@"Failed to push media: %@", error.localizedDescription);
                [self.view showFailureNotification:@"Failed to send media"];
            }
            else{
                [EWUIUtil dismissHUD];
            }
        }];
        
        //clean up
        recordingFileUrl = nil;
    }
}

//delegate
- (IBAction)close:(id)sender {
    if ([[EWAVManager sharedManager].recorder isRecording]) {
        [EWUIUtil showWarningHUBWithString:@"Woke is recording"];
    }
    else{
        [self dismissBlurViewControllerWithCompletionHandler:NULL];
    }
}


#pragma mark - Update progress
- (void)updateProgress:(CADisplayLink *)link {
    CGFloat progress = 0.0;
    if ([EWAVManager sharedManager].recorder.isRecording) {
        progress = (CGFloat) [EWAVManager sharedManager].recorder.currentTime /kMaxRecordTime;
        //set prpgress
        if (progress<1) {
            self.progressView.progress = progress;
            [self updateMeters];
        }
    }
    else if([EWAVManager sharedManager].player.isPlaying) {
        progress = (CGFloat) [EWAVManager sharedManager].player.currentTime /kMaxRecordTime;
        //set prpgress
        if (progress<1) {
            self.progressView.progress = progress;
            [self updateMeters];
        }
    }
}

- (void)stopUpdatingProgress:(NSNotification *)note{
    self.progressView.progress = 1;
    
    [self onStopButton:nil];
}

- (void)updateMeters{
    [[EWAVManager sharedManager].recorder updateMeters];
    CGFloat normalizedValue = (float)pow (10, [[EWAVManager sharedManager].recorder averagePowerForChannel:0]/30);
    [self.waveformView updateWithLevel:normalizedValue];
}

@end
