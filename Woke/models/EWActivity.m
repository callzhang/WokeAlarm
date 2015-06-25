#import "EWActivity.h"
#import "EWSession.h"
#import "EWMedia.h"

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
    activity.createdAt = [NSDate date];
    return activity;
}

+ (EWActivity *)getActivityWithID:(NSString *)ID error:(NSError **)error{
    return (EWActivity *)[EWSync findObjectWithClass:[[self class] serverClassName] withServerID:ID error:error];
}

- (NSArray *)medias{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId IN %@", self.mediaIDs];
    NSArray *medias = [EWMedia MR_findAllWithPredicate:predicate inContext:self.managedObjectContext];
    return medias;
}

- (BOOL)validate{
    BOOL good = YES;
    if (!self.owner) {
        DDLogError(@"Activity %@ missing owner", self.serverID);
        good = NO;
    }
    if (!self.alarmID) {
        DDLogError(@"Activity %@ missing alarmID", self.serverID);
        good = NO;
    }
    if (!self.time) {
        DDLogError(@"Activity %@ missing time", self.serverID);
        good = NO;
    }
    
    return good;
}

- (void)addMediaIDs:(NSArray *)serverIDs{
    NSMutableSet *mediaArray = [NSMutableSet setWithArray:self.mediaIDs] ?: [NSMutableSet new];
    [mediaArray addObjectsFromArray:serverIDs];
    self.mediaIDs = mediaArray.allObjects.mutableCopy;
}

-(EWServerObject *)ownerObject{
    return self.owner;
}
@end
