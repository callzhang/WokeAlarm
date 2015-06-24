//
//  EWMediaStore.m
//  EarlyWorm
//
//  Created by Lei on 8/2/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWMediaManager.h"
#import "EWMedia.h"
#import "EWPerson.h"

#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWActivity.h"
#import "NSArray+BlocksKit.h"
#import "EWUIUtil.h"
#import "NSDictionary+KeyPathAccess.h"
#import "EWMediaFile.h"

@implementation EWMediaManager

+(EWMediaManager *)sharedInstance{
    static EWMediaManager *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWMediaManager alloc] init];
    });
    return sharedStore_;
}

#pragma mark - Handle media push notification
- (void)handlePushMedia:(NSDictionary *)notification{
    EWAssertMainThread
    NSString *pushType = notification[kPushType];
    NSParameterAssert([pushType isEqualToString:kPushTypeMedia]);
    NSString *type = notification[kPushMediaType];
    NSString *mediaID = notification[kPushMediaID];
    
    if (!mediaID) {
        DDLogError(@"Push doesn't have media ID, abort!");
        return;
    }
    
    //download media
    EWMedia *media = [EWMedia getMediaByID:mediaID];
    //Woke state -> assign media to next task, download
    if (![[EWPerson me].unreadMedias containsObject:media]) {
		[[EWPerson me] addReceivedMediasObject:media];
        [[EWPerson me] save];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:nil];
    }
    
    //create notification
    [[EWNotificationManager shared] newMediaNotification:media];
    
    if ([type isEqualToString:kPushMediaTypeVoice]) {
        // ============== Media ================
        NSParameterAssert(mediaID);
        DDLogInfo(@"Received voice type push");
        
#ifdef DEBUG
        [[[UIAlertView alloc] initWithTitle:@"Voice来啦" message:@"收到一条神秘的语音."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#endif
        
    }else{
        
        // ============== Test ================
		NSString *str = [NSString stringWithFormat:@"Received === %@ === type media push", type];
        DDLogInfo(str);
        EWAlert(str);
        [UIApplication sharedApplication].applicationIconBadgeNumber = 99;
    }
}

#pragma mark - Get voice
- (EWMedia *)getWokeVoice{
	EWAssertMainThread
	NSError *error;
	EWMedia *newMedia;
	PFObject *media = [PFCloud callFunction:@"getWokeVoice" withParameters:@{kUserID: [EWPerson me].objectId} error:&error];
	if (media) {
		DDLogInfo(@"Finished get woke voice request with media: %@", media);
		//check media
			newMedia = [EWMedia getMediaByID:media.objectId inContext:mainContext];
			[[EWPerson me] addReceivedMediasObject:newMedia];
			[[EWNotificationManager sharedInstance] newMediaNotification:newMedia];
			[[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:newMedia];
		
	}else{
		DDLogError(@"Failed Woke voice request: %@", error.description);
	}
	
	return newMedia;
}


- (void)getWokeVoiceWithCompletion:(void (^)(EWMedia *, NSError *))block{
    //call server test function
    [PFCloud callFunctionInBackground:@"getWokeVoice" withParameters:@{kUserID: [EWPerson me].objectId} block:^(PFObject *media, NSError *error) {
        if (media) {
            DDLogInfo(@"Finished get woke voice request with media: %@", media);
            //check media
            [mainContext MR_saveWithBlock:^(NSManagedObjectContext *localContext) {
                EWMedia *newMedia = [EWMedia getMediaByID:media.objectId inContext:localContext];
                [[EWPerson meInContext:localContext] addReceivedMediasObject:newMedia];
            } completion:^(BOOL contextDidSave, NSError *error2) {
				EWMedia *m;
                if (contextDidSave) {
                    m = [EWMedia getMediaByID:media.objectId inContext:mainContext];
                    [[EWNotificationManager sharedInstance] newMediaNotification:m];
					[[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:m];
				}else {
					DDLogError(@"Failed to save new media: %@", error2);
				}
				
				if (block) {
					block(m, nil);
				}
            }];
        }else{
            DDLogError(@"Failed Woke voice request: %@", error.description);
			if (block) {
				block(nil, error);
			}
        }
    }];
}

- (void)testGetRandomVoiceWithCompletion:(void (^)(EWMedia *media, NSError *error))block{
	//call server test function
    NSArray *wokeVoiceIDReceived = [[EWPerson me].receivedMedias valueForKeyPath:[NSString stringWithFormat:@"%@.%@", EWMediaRelationships.mediaFile, kParseObjectID]];
    NSDictionary *params = @{kUserID: [EWPerson me].objectId, @"wokeVoiceReceived": wokeVoiceIDReceived?:@0};
	[PFCloud callFunctionInBackground:@"testGetRandomVoice" withParameters:params block:^(PFObject *media, NSError *error) {
		if (media) {
			DDLogInfo(@"Got random voice request with media: %@", media);
			//check media
			[mainContext MR_saveWithBlock:^(NSManagedObjectContext *localContext) {
				EWMedia *newMedia = [EWMedia getMediaByID:media.objectId inContext:localContext];
				[[EWPerson meInContext:localContext] addReceivedMediasObject:newMedia];
			} completion:^(BOOL contextDidSave, NSError *error2) {
				//notification
                EWMedia *m = (EWMedia *)[media managedObjectInContext:mainContext];
                [[EWNotificationManager sharedInstance] newMediaNotification:m];
                if (block) {
                    block(m, error2);
                }
                
                //broadcast
                [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:nil];
			}];
		}else{
			DDLogError(@"Failed random voice request: %@", error.description);
		}
	}];
}

- (void)checkMediaFilesForPerson:(EWPerson *)person{
	NSMutableSet *medias = person.sentMedias.mutableCopy;
	[medias unionSet:person.receivedMedias];
	[medias addObjectsFromArray:person.unreadMedias];
	//check
	for (EWMedia *media in medias) {
		[media downloadMediaFileWithCompletion:^(BOOL success, NSError *error) {
			if (!success) {
				DDLogWarn(@"Failed to update media %@", media.objectId);
			}
		}];
	}
}

- (NSArray *)checkNewMedias{
    EWAssertMainThread
    return [self checkNewMediasInContext:mainContext];
}

- (void)checkNewMediasWithCompletion:(ArrayBlock)block{
    
    __block NSArray *mediaIDsIncontext;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        mediaIDsIncontext = [[self checkNewMediasInContext:localContext] valueForKey:@"objectID"];
    } completion:^(BOOL contextDidSave, NSError *error) {
        if (contextDidSave && block) {
            NSMutableArray *medias = [NSMutableArray new];
            for (NSManagedObjectID *ID in mediaIDsIncontext) {
                NSManagedObject *MO = [mainContext existingObjectWithID:ID error:nil];
                [medias addObject:MO];
            }
            return block(medias.copy, nil);
        }
    }];
}

- (NSArray *)checkNewMediasInContext:(NSManagedObjectContext *)context{
    if (![PFUser currentUser]) {
        return nil;
    }
    EWPerson *localMe = [EWPerson meInContext:context];
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([EWMedia class])];
    [query whereKey:EWMediaRelationships.receiver equalTo:[PFUser currentUser]];
	NSSet *receivedMediaIDs = [localMe.receivedMedias valueForKey:kParseObjectID];
    if (receivedMediaIDs.count) [query whereKey:kParseObjectID notContainedIn:receivedMediaIDs.allObjects];
	NSError *err;
    NSArray *newMedia = [EWSync findManagedObjectFromServerWithQuery:query saveInContext:context error:&err];

    for (EWMedia *media in newMedia) {
		[media downloadMediaFile:nil];
        [[EWPerson meInContext:context] addReceivedMediasObject:media];
        //new media
		DDLogInfo(@"Received media(%@) from %@", media.objectId, media.author.name);
        //EWNotification
		dispatch_async(dispatch_get_main_queue(), ^{
			EWMedia *m = (EWMedia *)[media MR_inContext:mainContext];
			if (!m) {
				DDLogError(@"Cannot find media %@ on main thread! Cancel new media notification", media.serverID);
				return;
			}
			[[EWNotificationManager shared] newMediaNotification:m];
		});
    }
	
    if (newMedia.count) {
        //notify user for the new media
        dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
            [EWUIUtil showSuccessHUBWithString:@"Got voice for next wake up"];
#endif
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:nil];
        });
    }

	return [EWPerson meInContext:context].unreadMedias;
}

@end
