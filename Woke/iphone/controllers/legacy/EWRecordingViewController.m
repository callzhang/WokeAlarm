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
#import "EWCollectionPersonCell.h"
#import "UIViewController+Blur.h"
#define BUTTONCENTER  CGPointMake(470, EWScreenWidth/2)

@interface EWRecordingViewController ()<EWBaseViewNavigationBarButtonsDelegate>{
    NSURL *recordingFileUrl;
    CADisplayLink *displayLink;
}

@end

@implementation EWRecordingViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    [self initProgressView];
    
    if (!_wakees || _wakees.count == 0) {
        DDLogWarn(@"Wakees not set, use random person!");
        [[EWPersonManager shared] nextWakeeWithCompletion:^(EWPerson *person) {
            self.wakees = @[person];
            [self.peopleView reloadData];
        }];
    }

    

    
    //texts
    self.title = @"Recording";
    if (_wakees.count == 1) {
        EWPerson *receiver = _wakees.firstObject;
        
        NSString *statement = [[EWAlarmManager sharedInstance] nextStatementForPerson:receiver];
        
        self.detail.text = [NSString stringWithFormat:@"%@ wants to hear", receiver.name];
        if (statement) {
            _wish.text = [NSString stringWithFormat:@"\"%@\"", statement];
        }else{
            _wish.text = @"\"say good morning\"";
        }
        
    }else{
        self.detail.text = @"Sent voice greeting for their next morning";
        self.wish.text = @"";
    }

    //NavigationController
    if (!self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = [self.mainNavigationController menuBarButtonItem];
    }

    //waveform
    [self.waveformView setWaveColor:[UIColor colorWithWhite:1.0 alpha:0.75]];
    
    //collection view
    self.peopleView.backgroundColor = [UIColor clearColor];
    self.peopleView.hidden = YES;
}

-(void)initProgressView{
    
    self.progressView.tintColor = [UIColor whiteColor];
	self.progressView.borderWidth = 0.0;
	self.progressView.lineWidth = 1;
    
//	self.progressView.fillOnTouch = YES;
	
    UILabel *textLabel = (UILabel *)[self.view viewWithTag:30];
	self.progressView.centralView = textLabel;
	
	self.progressView.progressChangedBlock = ^(UAProgressView *progressView, float progress){
        
//        self.progressView.tintColor = [UIColor clearColor];
        
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

#pragma mark - collection view
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"recordingViewPersonCell" forIndexPath:indexPath];
    cell.showName = YES;
    cell.showTime = YES;
    EWPerson *receiver = _wakees[indexPath.row];
    cell.person = receiver;
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _wakees.count;
}

//center the wakee
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    
    NSInteger numberOfCells = _wakees.count;
    if (numberOfCells == 1) {
        UICollectionViewLayoutAttributes *attributes = [collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        CGFloat width = attributes.frame.size.width;
        NSInteger edgeInsets = (self.peopleView.frame.size.width - (numberOfCells * width) - numberOfCells * 10) / 2;
        edgeInsets = MAX(edgeInsets, 20);
        return UIEdgeInsetsMake(0, edgeInsets, 0, edgeInsets);
    }
    
    return UIEdgeInsetsZero;
}

#pragma mark- Actions

- (IBAction)play:(id)sender {
    
    if ([EWAVManager sharedManager].recorder.isRecording) {
        //stop recording
        [self record:nil];
        return ;
    }
    
    if (!recordingFileUrl){
        DDLogError(@"Recording url empty");
        return;
    }
    
    if (![EWAVManager sharedManager].player.isPlaying) {
        //play
        displayLink.paused = NO;
        [[EWAVManager sharedManager] playSoundFromURL:recordingFileUrl];
        //[self.playBtn setImage:[UIImage imageNamed:@"Stop Button"] forState:UIControlStateNormal];
        [UIView animateWithDuration:1 animations:^{
            self.recordBtn.alpha = 0;
            self.sendBtn.alpha = 0;
            self.retakeLabel.alpha = 0;
            self.sendLabel.alpha = 0;
            self.waveformView.alpha = 1;
            self.playLabel.text = @"Stop";
            [self.playBtn setTitle:@"Stop" forState:UIControlStateNormal];
        }];
    }else{
        [self stopPlaying];
    }
}

- (void)stopPlaying{
    displayLink.paused = YES;
    [UIView animateWithDuration:1 animations:^{
        self.recordBtn.alpha = 1;
        self.sendBtn.alpha = 1;
        self.retakeLabel.alpha = 1;
        self.sendLabel.alpha = 1;
        self.waveformView.alpha = 0;
        [self.playBtn setTitle:@"Play" forState:UIControlStateNormal];
        self.playLabel.text = @"Play";
    }];
    //[self.playBtn setImage:[UIImage imageNamed:@"Play Button"] forState:UIControlStateNormal];
    [[EWAVManager sharedManager] stopAllPlaying];
}


- (IBAction)record:(id)sender {
    
    if ([EWAVManager sharedManager].player.isPlaying) {
        //never happen
        return ;
    }
    
    //record
    if (![EWAVManager sharedManager].recorder.isRecording) {
        recordingFileUrl = [[EWAVManager sharedManager] record];
        displayLink.paused = NO;
        [UIView animateWithDuration:1.0 animations:^(){
            self.sendBtn.alpha = 0.0;
            self.recordBtn.alpha = 0.0;
            self.sendLabel.alpha = 0.0;
            self.retakeLabel.alpha = 0.0;
            self.waveformView.alpha = 1;
            self.playLabel.text = @"Stop";
            [self.playBtn setTitle:@"Stop" forState:UIControlStateNormal];
            //[self.playBtn setImage:[UIImage imageNamed:@"Stop Button Red "] forState:UIControlStateNormal];
            
        }];
    }else{
        [self stopRecording];
    }
}

- (void)stopRecording{
    [[EWAVManager sharedManager].recorder stop];
    displayLink.paused = YES;
    [UIView animateWithDuration:1.0 animations:^(){
        self.sendBtn.alpha = 1.0;
        self.recordBtn.alpha = 1.0;
        self.sendLabel.alpha = 1.0;
        self.retakeLabel.alpha = 1.0;
        self.waveformView.alpha = 0;
        self.retakeLabel.text = @"Retake";
        [self.recordBtn setTitle:@"Retake" forState:UIControlStateNormal];
        self.playLabel.text  = @"Play";
        [self.playBtn setTitle:@"Play" forState:UIControlStateNormal];
        //[self.playBtn setImage:[UIImage imageNamed:@"Play Button"] forState:UIControlStateNormal];
    }];
}

- (IBAction)send:(id)sender {
    if (recordingFileUrl) {
        [self.view showLoopingWithTimeout:0];
        
        //finished recording, prepare for data
        NSError *err;
        NSData *recordData = [NSData dataWithContentsOfFile:[recordingFileUrl path] options:0 error:&err];
        if (!recordData) {
            DDLogWarn(@"No recorded file found");
            return;
        }
        //NSString *fileName = [NSString stringWithFormat:@"voice_%@_%@.m4a", me.username, [[NSDate date] date2numberDateString]];
        
        //save data to task
        [self.view showLoopingWithTimeout:0];
        
        [[ATConnect sharedConnection] engage:kRecordVoiceSuccess fromViewController:self];
        
        EWMediaFile *mediaFile = [EWMediaFile newMediaFile];
        mediaFile.audio = recordData;
        mediaFile.owner = [EWPerson me].serverID;
        
        for (EWPerson *receiver in _wakees) {
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
                }else{
                    //dismiss hud
                    [EWUIUtil dismissHUDinView:self.view];
                    
                    //dismiss blur view
                    //[self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
                }
            }];
        }
        
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
    displayLink.paused = YES;
    if ([note.object isKindOfClass:[AVAudioPlayer class]]) {
        //stop
        [self stopPlaying];
    }
    else if ([note.object isKindOfClass:[AVAudioRecorder class]]){
        //stopped
        [self stopRecording];
    }
}

- (void)updateMeters{
    [[EWAVManager sharedManager].recorder updateMeters];
    CGFloat normalizedValue = (float)pow (10, [[EWAVManager sharedManager].recorder averagePowerForChannel:0]/30);
    [self.waveformView updateWithLevel:normalizedValue];
}

@end
