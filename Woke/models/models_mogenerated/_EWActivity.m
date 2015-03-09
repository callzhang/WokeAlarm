// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWActivity.m instead.

#import "_EWActivity.h"

const struct EWActivityAttributes EWActivityAttributes = {
	.alarmID = @"alarmID",
	.completed = @"completed",
	.mediaIDs = @"mediaIDs",
	.sleepTime = @"sleepTime",
	.statement = @"statement",
	.time = @"time",
	.type = @"type",
};

const struct EWActivityRelationships EWActivityRelationships = {
	.owner = @"owner",
};

const struct EWActivityFetchedProperties EWActivityFetchedProperties = {
	.myMedias = @"myMedias",
};

@implementation EWActivityID
@end

@implementation _EWActivity

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWActivity" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWActivity";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWActivity" inManagedObjectContext:moc_];
}

- (EWActivityID*)objectID {
	return (EWActivityID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic alarmID;

@dynamic completed;

@dynamic mediaIDs;

@dynamic sleepTime;

@dynamic statement;

@dynamic time;

@dynamic type;

@dynamic owner;

@dynamic myMedias;

@end

