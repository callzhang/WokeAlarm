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
#import "EWMediaFile.h"

@implementation EWMediaManager

+(EWMediaManager *)sharedInstance{
    EWAssertMainThread
    static EWMediaManager *sharedStore_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore_ = [[EWMediaManager alloc] init];
    });
    return sharedStore_;
}

#pragma mark - Handle media push notification
- (void)handlePushMedia:(NSDictionary *)notification{
    NSString *pushType = notification[kPushType];
    NSParameterAssert([pushType isEqualToString:kPushTypeMedia]);
    NSString *type = notification[kPushMediaType];
    NSString *mediaID = notification[kPushMediaID];
    
    if (!mediaID) {
        NSLog(@"Push doesn't have media ID, abort!");
        return;
    }
    
    //download media
    EWMedia *media = [EWMedia getMediaByID:mediaID];
    //Woke state -> assign media to next task, download
    if (![[EWPerson me].unreadMedias containsObject:media]) {
        [[EWPerson me] addUnreadMediasObject:media];
        [EWSync save];
    }
    
    if ([type isEqualToString:kPushMediaTypeVoice]) {
        // ============== Media ================
        NSParameterAssert(mediaID);
        NSLog(@"Received voice type push");
        
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
    [PFCloud callFunctionInBackground:@"getWokeVoice" withParameters:@{kUserID: [EWPerson me].objectId} block:^(id object, NSError *error) {
        if (object) {
            NSParameterAssert([object isKindOfClass:[NSString class]]);
            DDLogInfo(@"Finished get woke voice request with response: %@", object);
            //check media
            EWMedia *newMedia = [EWMedia getMediaByID:(NSString *)object];
            if (![newMedia validate]) {
                DDLogError(@"Get new woke voice but not valid: %@", newMedia);
                return;
            }
            DDLogVerbose(@"New media found: %@", newMedia.objectId);
            //make sure the relationship is established
            [[EWPerson me] addUnreadMediasObject:newMedia];
            [EWSync save];
            //notification
            [EWNotification newMediaNotification:newMedia];
        }else{
            DDLogError(@"Failed test voice request: %@", error.description);
        }
    }];
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
    EWPerson *localMe = [EWPerson meInContext:context];
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
    [mediasNeedToRefresh filterUsingPredicate:[NSPredicate predicateWithFormat:@"%K == nil", kParseObjectID]];
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
