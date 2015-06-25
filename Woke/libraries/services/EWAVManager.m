    //
//  EWAVManager.m
//  EarlyWorm
//
//  Created by Lei on 7/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWAVManager.h"
#import "EWMediaCell.h"
#import "EWMedia.h"
#import "EWMediaFile.h"
#import "EWStartUpSequence.h"
#import "EWMediaSlider.h"
#import "EWMediaManager.h"
#import "EWBackgroundingManager.h"
#import "EWAlarmManager.h"
#import "EWAlarm.h"
#import "NSTimer+BlocksKit.h"
#import "FBTweak.h"
#import "FBTweakInline.h"
@import MediaPlayer;


//NSString * const kEWAVManagerDidStopPlayNotification = @"kEWAVManagerDidStopPlayNotification";
NSString * const kEWAVManagerDidUpdateProgressNotification = @"kEWAVManagerDidUpdateProgressNotification";

@interface EWAVManager(){
	MPVolumeView *volumeView;
}
@property (nonatomic, weak) EWMedia *media;
@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, assign) BOOL maxVolume;
@end

@implementation EWAVManager


+(EWAVManager *)sharedManager{
    static EWAVManager *sharedManager_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager_ = [[EWAVManager alloc] init];
    });
    return sharedManager_;
}

-(id)init{
    //static EWAVManager *sharedManager_ = nil;
    self = [super init];
    if (self) {
        self.maxVolume = FBTweakValue(@"AVManager", @"Volume", @"Max Volume", YES);
        
        //recorder path
        NSString *tempDir = NSTemporaryDirectory ();
        NSString *soundFilePath =  [tempDir stringByAppendingString: @"recording.m4a"];
        recordingFileUrl = [[NSURL alloc] initFileURLWithPath: soundFilePath];
        
        //Volume view
		volumeView = [[MPVolumeView alloc] init];
        
        //audio session notification
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionInterruptionNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            static NSString *currentSessionType;
            NSNumber *type = (NSNumber *)note.userInfo[AVAudioSessionInterruptionTypeKey];
            if (type.integerValue == AVAudioSessionInterruptionTypeEnded) {
                NSNumber *option = note.userInfo[AVAudioSessionInterruptionOptionKey];
                NSInteger optionValue = option.integerValue;
                if (optionValue == AVAudioSessionInterruptionOptionShouldResume) {
                    if ([currentSessionType isEqualToString:@"playing"]) {
                        [self.player play];
                    }
                    else if ([currentSessionType isEqualToString:@"recording"]) {
                        [self.recorder record];
                    }
                }
            }
            else if (type.integerValue == AVAudioSessionInterruptionTypeBegan){
                if (self.player.playing) {
                    currentSessionType = @"playing";
                    [self.player pause];
                }
                else if (self.recorder.recording){
                    currentSessionType = @"recording";
                    [self.recorder pause];
                }
            }
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAVManagerDidStartPlaying) name:kAVManagerDidStartPlaying object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAVManagerDidStopPlaying) name:kAVManagerDidFinishPlaying object:nil];
    }
    return self;
}

#pragma mark - Audio Sessions
//register the ACTIVE playing session
- (void)registerActiveAudioSession{
	[self setDeviceVolume:1.0];
	[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    //audio session
    //[[AVAudioSession sharedInstance] setDelegate: self];
    NSError *error = nil;
    
    //set category
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback
													withOptions: AVAudioSessionCategoryOptionDuckOthers
														  error: &error];
    if (!success) DDLogVerbose(@"AVAudioSession error setting category:%@",error);
#ifdef DEBUG
	//#else
	success = [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
	if (!success)  DDLogError(@"AVAudioSession error overrideOutputAudioPort:%@",error);
#endif
	

	
    //set active
    success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success){
        DDLogError(@"Unable to activate ACTIVE audio session:%@", error);
    }
}

- (void)registerRecordingAudioSession{
    [self stopAllPlaying];
    //[[AVAudioSession sharedInstance] setDelegate: self];
    NSError *error = nil;
    
    //set category
    BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord
                                                    withOptions: AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth
                                                          error: &error];
    if (!success) DDLogVerbose(@"AVAudioSession error setting category:%@",error);
    
    //set active
    success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success || error){
        DDLogError(@"Unable to activate ACTIVE audio session:%@", error);
    }
}

#pragma mark - PLAY FUNCTIONS
- (void)playMedia:(EWMedia *)mi{
    EWAssertMainThread
    
	//set to max volume
	[self setDeviceVolume:1.0];
    if (!mi){
        [self playSoundFromFileName:kSilentSound];
    }else if (_media == mi){
        DDLogInfo(@"Same media passed in, skip.");
		if (!self.player.isPlaying) {
			[self.player play];
		}
        [[NSNotificationCenter defaultCenter] postNotificationName:kAVManagerDidStartPlaying object:mi];
        return;
    }
    else{
        //new media
        _media = mi;
		
		//lock screen
		[self displayNowPlayingInfoToLockScreen:mi];
		
        if ([mi.type isEqualToString:kMediaTypeVoice] || !mi.type) {
            NSParameterAssert (mi.mediaFile.audio);
            [self playSoundFromData:mi.mediaFile.audio];
//            }else{
//				[mi downloadMediaFileWithCompletion:^(BOOL success, NSError *error){
//                    if (error) {
//                        DDLogError(@"Failed to download media file: %@", error.description);
//                    }
//                    [self playSoundFromData:mi.mediaFile.audio];
//                }];
//            }
            
			[[NSNotificationCenter defaultCenter] postNotificationName:kAVManagerDidStartPlaying object:mi];
            
        }else{
            DDLogVerbose(@"Unknown type of media, skip");
            [self playSoundFromFileName:kSilentSound];
        }
    }
}

#pragma mark - Playing methods
//play for file in main bundle
-(void)playSoundFromFileName:(NSString *)fileName {
    
    NSArray *array = [fileName componentsSeparatedByString:@"."];
    
    NSString *file = nil;
    NSString *type = nil;
    if (array.count == 1) {
        file = fileName;
        type = @"";
    }else if (array.count == 2) {
        file = [array firstObject];
        type = [array lastObject];
    }else {
        EWAlert(@"Wrong file name(%@) passed to play sound", fileName);
        return;
    }
    NSString *str = [[NSBundle mainBundle] pathForResource:file ofType:type];
    if (!str) {
        EWAlert(@"File %@ doesn't exsits in main bundle", fileName);
        return;
    }
    NSURL *soundURL = [[NSURL alloc] initFileURLWithPath:str];
    //call the core play function
    [self playSoundFromURL:soundURL];
}

//play from url
- (void)playSoundFromURL:(NSURL *)url{
	if (!url) {
		DDLogError(@"Url is empty, skip playing");
		//[self audioPlayerDidFinishPlaying:player successfully:YES];
		return;
	}
	
	//data
	NSError *err;
	_player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    _player.delegate = self;
    _player.volume = 1.0;
    _player.meteringEnabled = YES;
	
	if (err) {
		DDLogVerbose(@"*** Cannot init player. Reason: %@", err);
		[self playSystemSound:url];
		return;
	}
	self.player.delegate = self;
	if ([_player play]){
		[[NSNotificationCenter defaultCenter] postNotificationName:kAVManagerDidStartPlaying object:url];
	}else{
		DDLogVerbose(@"*** Could not play with AVPlayer, using system sound");
		[self playSystemSound:url];
	}
}

- (void)playSoundFromData:(NSData *)data{
	if (!data || data.length == 0) {
		DDLogError(@"Playing from empty data");
		return;
	}
	NSError *err;
    //create player
	_player = [[AVAudioPlayer alloc] initWithData:data error:&err];
    _player.delegate = self;
	_player.volume = 1.0;
    _player.meteringEnabled = YES;
	
	if (err) {
		DDLogError(@"*** Cannot init AVAudioPlayer. Reason: %@", err);
		NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"audioTempFile"];
		[data writeToFile:path atomically:YES];
		[self playSystemSound:[NSURL URLWithString:path]];
		return;
	}
	_player.delegate = self;
	if ([_player play]){
		[[NSNotificationCenter defaultCenter] postNotificationName:kAVManagerDidStartPlaying object:data];
	}else{
		DDLogError(@"*** Could not play with AVAudioPlayer, using system sound");
		NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"audioTempFile"];
		[data writeToFile:path atomically:YES];
		[self playSystemSound:[NSURL URLWithString:path]];
	}
}

- (void)stopAllPlaying{
	[_player stop];
	//[qPlayer pause];
	[avplayer pause];
	//[updateTimer invalidate];
    self.media = nil;
}

#pragma mark - Record
- (NSURL *)record{
    if (_recorder.isRecording) {
        return nil;
    } else {
        [self registerRecordingAudioSession];
        NSDictionary *recordSettings = @{AVEncoderAudioQualityKey: @(AVAudioQualityLow),
                                         //AVEncoderAudioQualityKey: [NSNumber numberWithInt:kAudioFormatLinearPCM],
                                         //AVEncoderBitRateKey: @64,
                                         AVSampleRateKey: @24000.0,
                                         AVNumberOfChannelsKey: @1,
                                         AVFormatIDKey: @(kAudioFormatMPEG4AAC)}; //,
                                         //AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Variable};
        NSError *err;
        AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc] initWithURL: recordingFileUrl
                                                                   settings: recordSettings
                                                                      error: &err];
        self.recorder = newRecorder;
        _recorder.meteringEnabled = YES;
        _recorder.delegate = self;
        NSTimeInterval maxTime = kMaxRecordTime;
        [_recorder recordForDuration:maxTime];
        if (![_recorder prepareToRecord]) {
            DDLogVerbose(@"Unable to start record");
        };
        if (![_recorder record]){
            DDLogVerbose(@"Error: %@ [%ld])" , [err localizedDescription], (long)err.code);
            DDLogVerbose(@"Unable to record");
            return nil;
        }
        //post notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kAVManagerDidStartRecording object:nil];
        
    }
    return recordingFileUrl;
}

#pragma mark - update UI
- (float)playingProgress{
    float t = [EWAVManager sharedManager].player.currentTime;
    float T = [EWAVManager sharedManager].player.duration;
    return t/T;
}

- (void)onProgressTimer {
    CGFloat progress = self.playingProgress;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kEWAVManagerDidUpdateProgressNotification object:nil userInfo:@{@"progress": @(progress), @"media" : _media ? :[NSNull null]}];
    
    if ([EWSession sharedSession].wakeupStatus == EWWakeUpStatusWakingUp) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (void)startUpdateProgress {
    [self stopUpdateProgress];
    DDLogVerbose(@"Player Start");
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onProgressTimer) userInfo:nil repeats:YES];
}

- (void)stopUpdateProgress {
    DDLogVerbose(@"Player Stop");
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

- (void)onAVManagerDidStartPlaying {
    [self startUpdateProgress];
}

- (void)onAVManagerDidStopPlaying {
	[self stopUpdateProgress];
	self.player.currentTime = 0.0;
	if (self.audioFinishBlock) {
		self.audioFinishBlock(nil);
		self.audioFinishBlock = nil;
	}

    [[NSNotificationCenter defaultCenter] postNotificationName:kAVManagerDidFinishPlaying object:self.media];
}


#pragma mark - AVAudioPlayer delegate method
- (void)audioPlayerDidFinishPlaying: (AVAudioPlayer *)player successfully:(BOOL)flag {
    DDLogVerbose(@"Player finished (%@)", flag?@"Success":@"Failed");
	[self onAVManagerDidStopPlaying];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    DDLogVerbose(@"Recording stopped (%@)", flag?@"Success":@"Failed");
    [[NSNotificationCenter defaultCenter] postNotificationName:kAVManagerDidFinishRecording object:recorder];
}


#pragma  mark - System Sound Service
- (void)playSystemSound:(NSURL *)path{
    //release old id first
    AudioServicesRemoveSystemSoundCompletion(soundID);
    AudioServicesDisposeSystemSoundID(soundID);
    
    //SystemSound
    NSURL *soundUrl;
    if (!path) {
        soundUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tock" ofType:@"caf"]];
    }else{
        if ([path isFileURL] || ![path.absoluteString hasPrefix:@"http"]) {
            //local file
            soundUrl = path;
        }else{
            DDLogVerbose(@"Passed remote url to system audio service");
            soundUrl = path;
        }
    }
    
    //play
    DDLogVerbose(@"Start playing system sound");
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundUrl, &soundID);
    //AudioServicesPlayAlertSound(soundID);
    AudioServicesPlaySystemSound(soundID);
    [[NSNotificationCenter defaultCenter] postNotificationName:kAVManagerDidStartPlaying object:path];
    
    //long background server
    UIBackgroundTaskIdentifier bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        DDLogVerbose(@"Playing timer for system audio service is ending");
    }];
    
    //completion callback
    AudioServicesAddSystemSoundCompletion(soundID, nil, nil, systemSoundFinished, (void *)bgTaskId);
}

void systemSoundFinished (SystemSoundID sound, void *bgTaskId){
	[[EWAVManager sharedManager] onAVManagerDidStopPlaying];
    [[UIApplication sharedApplication] endBackgroundTask:(NSInteger)bgTaskId];
}


#pragma mark - Remote control
- (void)displayNowPlayingInfoToLockScreen:(EWMedia *)m{
    NSParameterAssert(m);
    if (!m.author) return;
        
    //only support iOS5+
    if (NSClassFromString(@"MPNowPlayingInfoCenter")){
        
        //self.media = m;
        EWAlarm *nextAlarm = [EWPerson myCurrentAlarm];
        
        NSString *title = nextAlarm.time.mt_stringFromDateWithFullWeekdayTitle;
        
        //info
        NSMutableDictionary *dict = [NSMutableDictionary new];
        dict[MPMediaItemPropertyTitle] = @"Time to wake up";
        dict[MPMediaItemPropertyArtist] = m.author.name?m.author.name:@"";
        dict[MPMediaItemPropertyAlbumTitle] = title?:@"";
        
        //cover
        UIImage *cover = m.mediaFile.image ?: m.author.profilePic;
        if (cover) {
            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:cover];
            dict[MPMediaItemPropertyArtwork] = artwork;
        }
        
        //set
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = dict;
        
        DDLogInfo(@"Set lock screen informantion");
    }
}



#pragma mark - Volume control
- (void)volumeTo:(float)volume withCompletion:(VoidBlock)block{
	float step = (volume-self.player.volume)>0 ? 0.1 : -0.1;
    if (ABS(self.player.volume - volume) > 0.1 && self.player) {
        self.player.volume = self.player.volume + step;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self volumeTo:volume withCompletion:block];
		});
    } else {
		self.player.volume = volume;
        if (block) {
            block();
        }
    }
}

- (void)setDeviceVolume:(float)volume{
    if (!self.maxVolume) {
        DDLogInfo(@"Skipped setting device volume");
        return;
    }
	UISlider* volumeViewSlider = nil;
	for (UIView *view in [volumeView subviews]){
		if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
			volumeViewSlider = (UISlider*)view;
			break;
		}
	}
	
	if (volumeViewSlider.value == volume) return;
	
	//change
	[volumeViewSlider setValue:volume animated:YES];
	[volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
	
	//change graduately
	/*
	[NSTimer bk_scheduledTimerWithTimeInterval:0.2 block:^(NSTimer *aTimer){
		float currentVolume = volumeViewSlider.value;
		float delta = volume - currentVolume;
		if (delta > 0.1) {
			delta = 0.1f;
		}else if(delta < -0.1){
			delta = -0.1f;
		}
		[volumeViewSlider setValue:currentVolume + delta animated:YES];
		[volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
		
		if (currentVolume == volume || !volumeViewSlider) {
			[aTimer invalidate];
			DDLogVerbose(@"Volume set to %f", volume);
			return;
		}
	} repeats:YES];
	*/
	
}

- (BOOL)isPlaying {
    return self.player.isPlaying;
}
@end
