// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWFriendRequest.m instead.

#import "_EWFriendRequest.h"

const struct EWFriendRequestAttributes EWFriendRequestAttributes = {
	.status = @"status",
};

const struct EWFriendRequestRelationships EWFriendRequestRelationships = {
	.receiver = @"receiver",
	.sender = @"sender",
};

@implementation EWFriendRequestID
@end

@implementation _EWFriendRequest

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWFriendRequest" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWFriendRequest";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWFriendRequest" inManagedObjectContext:moc_];
}

- (EWFriendRequestID*)objectID {
	return (EWFriendRequestID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic status;

@dynamic receiver;

@dynamic sender;

@end

