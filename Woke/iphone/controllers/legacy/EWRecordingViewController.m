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
#define BUTTONCENTER  CGPointMake(470, EWScreenWidth/2)

@interface EWRecordingViewController (){
    NSURL *recordingFileUrl;
    CADisplayLink *displayLink;
}

@end

@implementation EWRecordingViewController
@synthesize playBtn, recordBtn;
@synthesize wakees;

- (void)viewDidLoad{
    [super viewDidLoad];
    [self initProgressView];
    
    //texts
    self.title = @"Recording";
    if (wakees.count == 1) {
        EWPerson *receiver = wakees.anyObject;
        
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
    //[EWUIUtil addTransparantNavigationBarToViewController:self withLeftItem:nil rightItem:nil];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];

    //waveform
    [self.waveformView setWaveColor:[UIColor colorWithWhite:1.0 alpha:0.75]];
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
            [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%2.0f", [EWAVManager sharedManager].recorder.currentTime]];
            
        }
        if ([EWAVManager sharedManager].player.isPlaying) {
            [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%2.0f", [EWAVManager sharedManager].player.currentTime]];
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
//TODO: remove below methods?
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
//    EWCollectionPersonCell *cell = (EWCollectionPersonCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
//    cell.showName = NO;
//    EWPerson *receiver = personSet[indexPath.row];
//    cell.person = receiver;
//    return cell;
    return nil;
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return wakees.count;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(80, 100);
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    
//    NSInteger numberOfCells = personSet.count;
//    NSInteger edgeInsets = (self.peopleView.frame.size.width - (numberOfCells * kCollectionViewCellWidth) - numberOfCells * 10) / 2;
//    edgeInsets = MAX(edgeInsets, 20);
//    return UIEdgeInsetsMake(0, edgeInsets, 0, edgeInsets);
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
        //stop
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
}


- (IBAction)record:(id)sender {
    
    if ([EWAVManager sharedManager].player.isPlaying) {
        //never happen
        return ;
    }
    
    //record or stop
    recordingFileUrl = [[EWAVManager sharedManager] record];
    
    if ([EWAVManager sharedManager].recorder.isRecording) {
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
        //stopped
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
        
        for (EWPerson *receiver in wakees) {
            EWMedia *media = [EWMedia newMedia];
            media.type = kMediaTypeVoice;
            //media.message = self.message.text;
            
            //Add to media queue instead of task
            media.receiver = receiver;
            media.mediaFile = mediaFile;
            media.author = [EWPerson me];
            
            [EWServer pushVoice:media toUser:receiver withCompletion:^(BOOL success) {
                
                
                //dismiss hud
                [EWUIUtil dismissHUDinView:self.view];
                
                //dismiss
                //[self.presentingViewController dismissBlurViewControllerWithCompletionHandler:NULL];
            }];
        }
        
        //clean up
        recordingFileUrl = nil;
    }
}

- (IBAction)close:(id)sender {

    
    if ([[EWAVManager sharedManager].recorder isRecording]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Stop Record Before Close" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    else{
        //TODO: check
//        [self dismissBlurViewControllerWithCompletionHandler:NULL];
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
        [self play:nil];
    }
    else if ([note.object isKindOfClass:[AVAudioRecorder class]]){
        [self record:nil];
    }
}

- (void)updateMeters{
    [[EWAVManager sharedManager].recorder updateMeters];
    CGFloat normalizedValue = (float)pow (10, [[EWAVManager sharedManager].recorder averagePowerForChannel:0]/30);
    [self.waveformView updateWithLevel:normalizedValue];
}

@end
