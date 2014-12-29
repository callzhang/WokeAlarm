//
//  EWMediaStore.m
//  EarlyWorm
//
//  Created by Lei on 8/2/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import "EWMediaManager.h"
#import "EWMedia.h"
#import "EWImageManager.h"
#import "EWPerson.h"

#import "EWNotificationManager.h"
#import "EWNotification.h"
#import "EWActivity.h"
#import "NSArray+BlocksKit.h"
#import "EWAlarmManager.h"
#import "EWAlarm.h"
#import "NSDictionary+KeyPathAccess.h"

@implementation EWMediaManager
//@synthesize context, model;
@synthesize myMedias;
//@synthesize context;

+(EWMediaManager *)sharedInstance{
    EWAssertMainThread
    static EWMediaManager *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWMediaManager alloc] init];
    });
    return sharedStore_;
}


- (NSArray *)myMedias{
    EWAssertMainThread
    return [self mediasForPerson:[EWPerson me]];
}


- (EWMedia *)getWokeVoice{
    PFQuery *q = [PFQuery queryWithClassName:@"EWMedia"];
    [q whereKey:EWMediaRelationships.author equalTo:[PFQuery getUserObjectWithId:WokeUserID]];
    [q whereKey:EWMediaAttributes.type equalTo:kPushMediaTypeVoice];
    NSArray *mediasFromWoke = [EWPerson me].cachedInfo[kWokeVoiceReceived]?:[NSArray new];
#if !DEBUG
    [q whereKey:kParseObjectID notContainedIn:mediasFromWoke];
#endif
    NSArray *voices = [EWSync findServerObjectWithQuery:q error:nil];
    NSUInteger i = arc4random_uniform(voices.count);
    PFObject *voice = voices[i];
    if (voice) {
        EWMedia *media = (EWMedia *)[voice managedObjectInContext:nil];
        [media refresh];
        //add to my unread medias
        [[EWPerson me] addUnreadMediasObject:media];
        DDLogDebug(@"Got woke voice %@", media.objectId);
        //save
        NSMutableDictionary *cache = [[EWPerson me].cachedInfo mutableCopy];
        NSMutableArray *receivedVoices = [mediasFromWoke mutableCopy];
        [receivedVoices addObject:media.objectId];
        [cache setObject:receivedVoices forKey:kWokeVoiceReceived];
        [EWPerson me].cachedInfo = [cache copy];
        [EWSync save];
        
        return media;
    }
    return nil;
}

//possible redundant API, my media should be ready on start
- (NSArray *)mediaCreatedByPerson:(EWPerson *)person{
    NSArray *medias = [person.sentMedias allObjects];
    if (medias.count == 0 && [person isMe]) {
        //query
        PFQuery *q = [[[PFUser currentUser] relationForKey:EWPersonRelationships.sentMedias] query];
        [EWSync findServerObjectInBackgroundWithQuery:q completion:^(NSArray *objects, NSError *error) {
            [mainContext saveWithBlock:^(NSManagedObjectContext *localContext) {
                EWPerson *localMe = [[EWPerson me] MR_inContext:localContext];
                NSArray *newMedias = [objects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT %K IN %@", kParseObjectID, [localMe.sentMedias valueForKey:kParseObjectID]]];
                for (PFObject *m in newMedias) {
                    EWMedia *media = (EWMedia *)[m managedObjectInContext:localContext];
                    [media refresh];
                    [localMe addSentMediasObject:media];
                    [media saveToLocal];
                }
                [localMe saveToLocal];
                DDLogInfo(@"My media updated with %lu new medias", (unsigned long)newMedias.count);
            }];
        }];
    }
    return medias;
}

- (NSArray *)mediasForPerson:(EWPerson *)person{
    NSMutableArray *medias = [[NSMutableArray alloc] init];
    for (EWActivity *activity in person.activities) {
        for (EWMedia *media in activity.medias) {
            [medias addObject:media];
        }
    }
    //sort
    [medias sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWServerObjectAttributes.createdAt ascending:YES]]];
    
    return medias;
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
            return block(medias.copy);
        }
    }];
}

- (NSArray *)checkUnreadMediasInContext:(NSManagedObjectContext *)context{
    if (![PFUser currentUser]) {
        return nil;
    }
    EWPerson *localMe = [[EWPerson me] MR_inContext:context];
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([EWMedia class])];
    [query whereKey:EWMediaRelationships.receiver equalTo:[PFUser currentUser]];
    NSSet *localAssetIDs = [localMe.unreadMedias valueForKey:kParseObjectID];
    [query whereKey:kParseObjectID notContainedIn:localAssetIDs.allObjects];
    NSArray *mediaPOs = [EWSync findServerObjectWithQuery:query error:nil];
	NSMutableArray *newMedia = [NSMutableArray new];
    for (PFObject *po in mediaPOs) {
        //EWMedia *mo = (EWMedia *)[po managedObjectInContext:context];
        EWMedia *mo = [EWMedia getMediaByID:po.objectId];
        mo.receiver = [EWPerson me];
        [[EWPerson me] addUnreadMediasObject:mo];
        //new media
        //[mo refresh];
        DDLogInfo(@"Received media(%@) from %@", mo.objectId, mo.author.name);
        //notification
        if ([NSThread isMainThread]) {
            [EWNotification newMediaNotification:mo];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                EWMedia *media = (EWMedia *)[mo MR_inContext:mainContext];
                [EWNotification newMediaNotification:media];
            });
        }
        
        [newMedia addObject:mo];
    }
	
    if (newMedia.count) {
        //notify user for the new media
        dispatch_async(dispatch_get_main_queue(), ^{
            EWAlert(@"You got voice for your next wake up");
        });
    }
    
    //check exisitng media
    NSMutableSet *mediasNeedToRefresh = localMe.unreadMedias.mutableCopy;
    [mediasNeedToRefresh unionSet:localMe.receivedMedias];
    [mediasNeedToRefresh unionSet:localMe.sentMedias];
    [mediasNeedToRefresh filterUsingPredicate:[NSPredicate predicateWithFormat:@"%K != nil", kParseObjectID]];
    for (EWMedia *media in mediasNeedToRefresh) {
        DDLogVerbose(@"%s Refresh media: %@",__FUNCTION__, media.objectId);
        [media refresh];
    }
    
    return newMedia.copy;
}

- (NSArray *)unreadMediasForPerson:(EWPerson *)person{
    NSArray *unreadMedias = person.unreadMedias.allObjects;
    //filter only target date not in the future
    NSArray *unreadMediasForToday = [unreadMedias bk_select:^BOOL(EWMedia *obj) {
        if (!obj.targetDate) {
            return YES;
        }else if ([obj.targetDate timeIntervalSinceDate:[EWPerson myCurrentAlarm].time.nextOccurTime] < 0){
            return YES;
        }
        return NO;
    }];
    //sort by priority and created date
    unreadMediasForToday = [unreadMediasForToday sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:EWMediaAttributes.priority ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    return unreadMediasForToday;
    
}

@end
