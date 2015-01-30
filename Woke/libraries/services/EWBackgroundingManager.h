//
//  EWSleepManager.h
//  Woke
//
//  Created by Lee on 8/6/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

@import Foundation;
@import AVFoundation;
@import AudioToolbox;

#define kBackgroundingStartNotice	@"enter_backgrounding"
#define kBackgroundingEndNotice		@"end_backgrounding"
#define backgroundingSound          @"bg.caf"
#define backgroundingFailureSound   @"new.caf"

@interface EWBackgroundingManager : NSObject <AVAudioSessionDelegate>
@property (nonatomic, getter=isBackgrounding) BOOL backgrounding;

+ (EWBackgroundingManager *)sharedInstance;
- (void)startBackgrounding;
- (void)endBackgrounding;
/**
 *register for backgrounding AudioSession
 @discussion This session starts with option of mix & speaker
 */
- (void)registerBackgroudingAudioSession;

@end
