#import "EWActivity.h"
#import "EWSession.h"
#import "EWMedia.h"

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

- (void)awakeFromInsert{
    [super awakeFromInsert];
    [self setPrimitiveValue:[NSMutableArray array] forKey:EWActivityAttributes.mediaIDs];
}

+ (EWActivity *)newActivity{
    EWActivity *activity = [EWActivity MR_createEntity];
    activity.owner = [EWPerson me];
    activity.updatedAt = [NSDate date];
    return activity;
}

+ (EWActivity *)getActivityWithID:(NSString *)ID{
    return (EWActivity *)[EWSync findObjectWithClass:NSStringFromClass([self class]) withID:ID error:nil];
}

- (NSArray *)medias{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId IN %@", self.mediaIDs];
    NSArray *medias = [EWMedia MR_findAllWithPredicate:predicate inContext:self.managedObjectContext];
    return medias;
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
        if (!self.time) {
            DDLogError(@"Activity %@ missing time", self.objectId);
            good = NO;
        }
    }
    
    return good;
}

- (void)addMediaID:(NSString *)serverID{
    NSMutableSet *mediaArray = [NSMutableSet setWithArray:self.mediaIDs] ?: [NSMutableSet new];
    [mediaArray addObject:serverID];
    self.mediaIDs = mediaArray.allObjects;
    [self save];
}


- (EWActivity *)createWithPerson:(EWPerson *)person friended:(BOOL)friended {
    EWActivity *activity = [EWActivity newActivity];
    activity.type = EWActivityTypes.friendship;
    activity.friendedValue = friended;
    activity.friendID = person.objectId;
    
    return activity;
}

-(EWServerObject *)ownerObject{
    return self.owner;
}
@end
