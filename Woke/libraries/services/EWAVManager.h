//
//  EWAVManager.h
//  EarlyWorm
//
//  Created by Lei on 7/29/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//
/**  EWAVManager: Controls the overall audio/video play
//
//  - playForCell: highest level of control, controlled by WakeUpManager
//          |
//  - playMedia: Intermediate level of play, controlled by EWAVManager self
//          |
//  - playSoundFromURL: Lower level control, may called from outside
//
*/

@import Foundation;
@import AVFoundation;
@import AudioToolbox;
#import "EWDefines.h"
#import "SCSiriWaveformView.h"


#define kSilentSound            @"Silence04s.caf"

@class EWMediaCell, EWMedia, EWMediaSlider;

@interface EWAVManager : UIResponder <AVAudioPlayerDelegate, AVAudioRecorderDelegate, AVAudioSessionDelegate>
{
    //CALevelMeter *lvlMeter_in;
    NSTimer *updateTimer;
    NSURL *recordingFileUrl;
    AVPlayer *avplayer;
    SystemSoundID soundID;
}

@property (retain, nonatomic) AVAudioPlayer *player;
@property (retain, nonatomic) AVAudioRecorder *recorder;
//@property (weak, nonatomic) EWMediaCell *currentCell; //current cell, assigned by others
@property (weak, nonatomic) EWMedia *media;
@property (weak, nonatomic) UIButton *recordStopBtn;
@property (weak, nonatomic) UIButton *playStopBtn;
//@property (nonatomic) EWMediaSlider *progressBar;
@property (weak, nonatomic) UILabel *currentTime;
@property (weak, nonatomic) SCSiriWaveformView *waveformView;
//@property (nonatomic) BOOL loop;

+(EWAVManager *)sharedManager;

//play
//- (void)playForCell:(UITableViewCell *)cell;
- (void)playMedia:(EWMedia *)media;

/**
 Main play function. Support FTW cache method.
 */
- (void)playSoundFromURL:(NSURL *)url;
- (void)playSoundFromFileName:(NSString *)fileName;

//update states
//- (void)updateViewForPlayerState:(AVAudioPlayer *)player;


- (NSURL *)record;

// - (void)stopPlaying:(NSString *)fileName;
- (void)stopAllPlaying;


/**
 *register for ACTIVE PLAYING AudioSession
 */
- (void)registerActiveAudioSession;

/**
 *register for RECORDING AudioSession
 */
- (void)registerRecordingAudioSession;

/**
 Play audio using AVPlayer
 */
//- (void)playAvplayerWithURL:(NSURL *)url;
//- (void)playSilentSound;
//- (void)stopAvplayer;

/**
 Play sound with system sound service
 */
- (void)playSystemSound:(NSURL *)path;



/**
 Display the playing info to lock screen
 */
- (void)displayNowPlayingInfoToLockScreen:(EWMedia *)media;

///**
// *Register self as the first responder for remote control event
// */
//- (void)prepareRemoteControlEventsListener;
///**
// *Resign self as the first responder for remote control event
// */
//- (void)resignRemoteControlEventsListener;

#pragma mark - Tools
- (void)volumeFadeWithCompletion:(void (^)(void))block;
- (void)setDeviceVolume:(float)volume;
@end
