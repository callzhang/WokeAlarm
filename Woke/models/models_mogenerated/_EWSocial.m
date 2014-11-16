// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWSocial.m instead.

#import "_EWSocial.h"

const struct EWSocialAttributes EWSocialAttributes = {
	.addressBookFriends = @"addressBookFriends",
	.facebookFriends = @"facebookFriends",
	.facebookToken = @"facebookToken",
	.facebookUpdated = @"facebookUpdated",
	.weiboFriends = @"weiboFriends",
	.weiboToken = @"weiboToken",
	.weiboUpdated = @"weiboUpdated",
};

const struct EWSocialRelationships EWSocialRelationships = {
	.owner = @"owner",
};

@implementation EWSocialID
@end

@implementation _EWSocial

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWSocial" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWSocial";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWSocial" inManagedObjectContext:moc_];
}

- (EWSocialID*)objectID {
	return (EWSocialID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic addressBookFriends;

@dynamic facebookFriends;

@dynamic facebookToken;

@dynamic facebookUpdated;

@dynamic weiboFriends;

@dynamic weiboToken;

@dynamic weiboUpdated;

@dynamic owner;

@end

