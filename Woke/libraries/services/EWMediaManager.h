//
//  EWMediaStore.h
//  EarlyWorm
//
//  Created by Lei on 8/2/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#include <stdlib.h>
#import "EWPersonManager.h"

//#define buzzSounds                      @{@"default": @"buzz.caf"};
#define kWokeVoiceReceived              @"woke_voice_received"//the ramdom voice alraddy received, stored in cache

@class EWMedia;
@interface EWMediaManager : NSObject //EWStore

/**
 *Handles push media in varies mode
 @Discuss
 *   Voice
 *   active:
 *       alarm time passed but not woke(struggle): play media
 *       before alarm: download
 *       woke: alert with no name
 *   suspend: background download
 */
- (void)handlePushMedia:(NSDictionary *)notification;


+ (EWMediaManager *)sharedInstance;

/**
 Check unread medias
 Moved to EWPerson+Woke
 */
//- (NSArray *)unreadMediasForPerson:(EWPerson *)person;

/**
 *Check all my meidas, making sure they have the media file ready.
 */
- (void)checkMediaFilesForPerson:(EWPerson *)person;

/**
 *  check new medias from server, in sync
 *
 *  @return List of NEW medias
 */
- (NSArray *)checkNewMedias;
/**
 *  Check new medias from server, async
 *
 */
- (void)checkNewMediasWithCompletion:(ArrayBlock)block;

//get ramdom voice
- (EWMedia *)getWokeVoice;
- (void)getWokeVoiceWithCompletion:(void (^)(EWMedia *media, NSError *error))block;
- (void)testGetRandomVoiceWithCompletion:(void (^)(EWMedia *media, NSError *error))block;
@end;
