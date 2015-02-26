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
//#import "EWAlarmManager.h"
//#import "EWAlarm.h"
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
        [[EWPerson me] addUnreadMediasObject:media];
        [[EWPerson me] save];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:nil];
    }
    
    if ([type isEqualToString:kPushMediaTypeVoice]) {
        // ============== Media ================
        NSParameterAssert(mediaID);
        DDLogInfo(@"Received voice type push");
        
#ifdef DEBUG
        [[[UIAlertView alloc] initWithTitle:@"Voice来啦" message:@"收到一条神秘的语音."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#endif
        
    }else if([type isEqualToString:@"test"]){
        
        // ============== Test ================
        
        DDLogInfo(@"Received === test === type push");
        EWAlert(@"Received === test === type push");
        [UIApplication sharedApplication].applicationIconBadgeNumber = 99;
    }
}


- (void)getWokeVoice{
    //call server test function
    [PFCloud callFunctionInBackground:@"getWokeVoice" withParameters:@{kUserID: [EWPerson me].objectId} block:^(PFObject *media, NSError *error) {
        if (media) {
            DDLogInfo(@"Finished get woke voice request with media: %@", media);
            //check media
            [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
                EWMedia *newMedia = [EWMedia getMediaByID:media.objectId inContext:localContext];
                [[EWPerson meInContext:localContext] addUnreadMediasObject:newMedia];
            } completion:^(BOOL contextDidSave, NSError *error2) {
				if (contextDidSave) {
					[[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:nil];
				}else {
					DDLogError(@"Failed to save new media: %@", error2);
				}
            }];
        }else{
            DDLogError(@"Failed Woke voice request: %@", error.description);
        }
    }];
}

- (void)testGetRandomVoiceWithCompletion:(void (^)(EWMedia *media, NSError *error))block{
	//call server test function
	[PFCloud callFunctionInBackground:@"testGetRandomVoice" withParameters:@{kUserID: [EWPerson me].objectId} block:^(PFObject *media, NSError *error) {
		if (media) {
			DDLogInfo(@"Got random voice request with media: %@", media);
			//check media
			[mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
				EWMedia *newMedia = [EWMedia getMediaByID:media.objectId inContext:localContext];
				[[EWPerson meInContext:localContext] addUnreadMediasObject:newMedia];
			} completion:^(BOOL contextDidSave, NSError *error2) {
				//notification
				if (contextDidSave) {
					[[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:nil];
				}else {
					DDLogError(@"Failed to save new media: %@", error2);
				}
			}];
		}else{
			DDLogError(@"Failed random voice request: %@", error.description);
		}
	}];
}

//possible redundant API, my media should be ready on start
- (NSArray *)mediaCreatedByPerson:(EWPerson *)person{
    NSArray *medias = [person.sentMedias allObjects];
    if (medias.count == 0 && [person isMe]) {
        //query
        PFQuery *q = [[[PFUser currentUser] relationForKey:EWPersonRelationships.sentMedias] query];
		[q whereKey:kParseObjectID notContainedIn:[EWPerson me].sentMedias.allObjects];
		NSArray *MOs = [EWSync findParseObjectWithQuery:q inContext:person.managedObjectContext error:nil];
		for (EWMedia *m in MOs) {
			NSAssert(m.author == [EWPerson me], @"EWMedia's author missing: %@", m.serverID);
		}
		DDLogInfo(@"My media updated with %lu new medias", (unsigned long)MOs.count);
    }
    return medias;
}

- (void)checkMediasForPerson:(EWPerson *)person{
	NSMutableSet *medias = person.sentMedias.mutableCopy;
	[medias unionSet:person.receivedMedias];
	[medias unionSet:person.unreadMedias];
	//check
	for (EWMedia *media in medias) {
		[media downloadMediaFileWithCompletion:^(BOOL success, NSError *error) {
			if (success) {
				DDLogInfo(@"Updated media %@", media.objectId);
			}
		}];
	}
}

- (NSArray *)checkUnreadMedias{
    EWAssertMainThread
    return [self checkUnreadMediasInContext:mainContext];
}

- (void)checkUnreadMediasWithCompletion:(ArrayBlock)block{
    EWAssertMainThread
    __block NSArray *mediaIDsIncontext;
    [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
        mediaIDsIncontext = [[self checkUnreadMediasInContext:localContext] valueForKey:@"objectID"];
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

- (NSArray *)checkUnreadMediasInContext:(NSManagedObjectContext *)context{
    if (![PFUser currentUser]) {
        return nil;
    }
    EWPerson *localMe = [EWPerson meInContext:context];
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([EWMedia class])];
    [query whereKey:EWMediaRelationships.receiver equalTo:[PFUser currentUser]];
    NSSet *unreadMediaIDs = [localMe.unreadMedias valueForKey:kParseObjectID];
	NSSet *receivedMediaIDs = [localMe.receivedMedias valueForKey:kParseObjectID];
    [query whereKey:kParseObjectID notContainedIn:[unreadMediaIDs setByAddingObjectsFromSet:receivedMediaIDs].allObjects];
	NSError *err;
    NSArray *newMedia = [EWSync findParseObjectWithQuery:query inContext:context error:&err];

    for (EWMedia *media in newMedia) {
		[media downloadMediaFile];
        [[EWPerson me] addUnreadMediasObject:media];
        //new media
		DDLogInfo(@"Received media(%@) from %@", media.objectId, media.author.name);
        //EWNotification
        if ([NSThread isMainThread]) {
            [EWNotification newMediaNotification:media];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                EWMedia *m = (EWMedia *)[media MR_inContext:mainContext];
                [EWNotification newMediaNotification:m];
            });
        }
    }
	
    if (newMedia.count) {
        //notify user for the new media
        dispatch_async(dispatch_get_main_queue(), ^{
            EWAlert(@"You got voice for your next wake up");
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:nil];
        });
    }

	return [[EWMediaManager sharedInstance] unreadMediasForPerson:[EWPerson meInContext:context]];
}

- (NSArray *)unreadMediasForPerson:(EWPerson *)person{
    NSArray *unreadMedias = person.unreadMedias.allObjects;
    //filter only target date not in the future
    NSArray *unreadMediasForToday = [unreadMedias bk_select:^BOOL(EWMedia *obj) {
        if (!obj.targetDate) {
            return YES;
        }else if ([obj.targetDate timeIntervalSinceDate:[EWPerson myCurrentAlarmActivity].time.nextOccurTime] < 0){
            return YES;
        }
        return NO;
    }];
    //sort by priority and created date
    unreadMediasForToday = [unreadMediasForToday sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWMediaAttributes.priority ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    return unreadMediasForToday;
    
}

@end
