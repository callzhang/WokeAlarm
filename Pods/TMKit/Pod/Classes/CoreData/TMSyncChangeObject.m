//
//  TMSyncChangeObject.m
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

#import "TMSyncChangeObject.h"
#import "TIManagedObjectExtensions.h"
#import "TMCoreDataConstants.h"

@implementation TMSyncChangeObject

#pragma mark - Helper Methods
+ (instancetype)createdSyncChangeOfType:(TMSyncChangeType)aType inManagedObjectContext:(NSManagedObjectContext *)aMoc {
    TMSyncChangeObject *syncChange = [self ti_objectInManagedObjectContext:aMoc];

    [syncChange setLocalTimeStamp:[NSDate date]];
    [syncChange setChangeType:[NSNumber numberWithInt:aType]];

    return syncChange;
}

#pragma mark - Inspection
- (NSString *)shortDescription {
    return [NSString stringWithFormat:@"%@ %@", TMSyncChangeTypeNames[ [[self changeType] unsignedIntValue] ], [self objectEntityName]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"\n%@\nCHANGED ATTRIBUTES\n%@\nCHANGED RELATIONSHIPS\n%@", [super description], [self changedAttributes], [self changedRelationships]];
}

#pragma mark - TIManagedObjectExtensions
+ (NSString *)ti_entityName
{
    return NSStringFromClass([self class]);
}

@dynamic changeType;
@synthesize relevantManagedObject = _relevantManagedObject;
@dynamic objectEntityName;
@dynamic objectSyncID;
@dynamic changedAttributes;
@dynamic changedRelationships;
@dynamic relevantKey;
@dynamic localTimeStamp;
@dynamic relatedObjectEntityName;
@end
