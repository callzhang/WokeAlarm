//
//  EWSharedSession.m
//  Woke
//
//  Created by Lei Zhang on 10/26/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWSession.h"
#import "EWPerson.h"



@implementation EWSession
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_WITH_ACCESSOR(EWSession, sharedSession);
- (EWSession *)init {
    self = [super init];
    if (self) {
        NSString *cachedDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        self.cachePath = [cachedDir stringByAppendingString:@"/sessionCache.arch"];
        [self load];
    }
    return self;
}

+ (NSManagedObjectContext *)mainContext{
    return [EWSession sharedSession].context;
}

- (void)load {
    
    EWSession *tmp = nil;
    @try {
        tmp = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cachePath];
    } @catch (NSException *exception) {
        // log the error.
        DDLogInfo(@"### Seems the archive uses an old format.");
        return;
    }
    
    if (tmp) {
        self.currentUserObjectID = tmp -> _currentUserObjectID;
    }
}

- (void)save {
    
    [NSKeyedArchiver archiveRootObject:self toFile:self.cachePath];
    DDLogInfo(@"session saved %@", self);
}

#pragma mark - Getter and Setter
- (NSMutableDictionary *)skippedWakees{
    if (_skippedWakees) {
        _skippedWakees  = [NSMutableDictionary new];
    }
    return _skippedWakees;
}

- (void)setCurrentUserObjectID:(NSString *)currentUserObjectID{
    if (currentUserObjectID) {
        EWPerson *me = [EWPerson MR_findFirstByAttribute:EWServerObjectAttributes.objectId withValue:currentUserObjectID];
        
        NSParameterAssert([[PFUser currentUser].objectId isEqualToString:me.objectId]);
        self.currentUser = me;
    }
}


#pragma mark - Persistancy

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_currentUserObjectID forKey:@"currentUserObjectID"];
    [encoder encodeObject:_skippedWakees forKey:@"skippedUsers"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self.currentUserObjectID = [decoder decodeObjectForKey:@"currentUserObjectID"];
    self.skippedWakees = [decoder decodeObjectForKey:@"skippedUsers"];
    return self;
}

@end
