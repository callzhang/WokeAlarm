#import "EWActivity.h"
#import "EWSession.h"

const struct EWActivityTypes EWActivityTypes = {
    .media = @"media",
    .friendship = @"friendship",
    .alarm = @"alarm"
};

@interface EWActivity ()

// Private interface goes here.

@end

@implementation EWActivity
@dynamic mediaIDs;

+ (EWActivity *)newActivity{
    EWActivity *activity = [EWActivity MR_createEntity];
    activity.owner = [EWPerson me];
    activity.updatedAt = [NSDate date];
    return activity;
}

- (void)remove{
    [self MR_deleteEntity];
    [EWSync save];
}

- (BOOL)validate{
    BOOL good = YES;
    if (!self.owner) {
        good = NO;
    }
    if (!self.type) {
        good = NO;
    }
    else if ([self.type isEqualToString:EWActivityTypes.alarm]) {
        if (self.time) {
            DDLogError(@"Activity %@ missing time", self.objectId);
            good = NO;
        }
    }
    
    return good;
}

- (void)addMediaID:(NSString *)objectID{
    NSMutableArray *mediaArray = self.mediaIDs.mutableCopy ?: [NSMutableArray new];
    [mediaArray addObject:objectID];
    self.mediaIDs = mediaArray.copy;
    [EWSync save];
}


- (EWActivity *)createWithPerson:(EWPerson *)person friended:(BOOL)friended {
    EWActivity *activity = [EWActivity newActivity];
    activity.type = EWActivityTypes.friendship;
    activity.friendedValue = friended;
    activity.friendID = person.objectId;
    
    return activity;
}


@end
