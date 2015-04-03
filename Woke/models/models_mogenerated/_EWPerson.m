// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWPerson.m instead.

#import "_EWPerson.h"

const struct EWPersonAttributes EWPersonAttributes = {
	.bgImage = @"bgImage",
	.birthday = @"birthday",
	.cachedInfo = @"cachedInfo",
	.city = @"city",
	.country = @"country",
	.email = @"email",
	.firstName = @"firstName",
	.gender = @"gender",
	.history = @"history",
	.images = @"images",
	.lastName = @"lastName",
	.location = @"location",
	.preference = @"preference",
	.profilePic = @"profilePic",
	.socialProfileID = @"socialProfileID",
	.statement = @"statement",
	.username = @"username",
};

const struct EWPersonRelationships EWPersonRelationships = {
	.achievements = @"achievements",
	.activities = @"activities",
	.alarms = @"alarms",
	.friends = @"friends",
	.friendshipRequestReceived = @"friendshipRequestReceived",
	.friendshipRequestSent = @"friendshipRequestSent",
	.notifications = @"notifications",
	.receivedMedias = @"receivedMedias",
	.receivedMessages = @"receivedMessages",
	.sentMedias = @"sentMedias",
	.sentMessages = @"sentMessages",
	.socialGraph = @"socialGraph",
};

@implementation EWPersonID
@end

@implementation _EWPerson

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EWPerson" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EWPerson";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EWPerson" inManagedObjectContext:moc_];
}

- (EWPersonID*)objectID {
	return (EWPersonID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic bgImage;

@dynamic birthday;

@dynamic cachedInfo;

@dynamic city;

@dynamic country;

@dynamic email;

@dynamic firstName;

@dynamic gender;

@dynamic history;

@dynamic images;

@dynamic lastName;

@dynamic location;

@dynamic preference;

@dynamic profilePic;

@dynamic socialProfileID;

@dynamic statement;

@dynamic username;

@dynamic achievements;

- (NSMutableSet*)achievementsSet {
	[self willAccessValueForKey:@"achievements"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"achievements"];

	[self didAccessValueForKey:@"achievements"];
	return result;
}

@dynamic activities;

- (NSMutableSet*)activitiesSet {
	[self willAccessValueForKey:@"activities"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"activities"];

	[self didAccessValueForKey:@"activities"];
	return result;
}

@dynamic alarms;

- (NSMutableSet*)alarmsSet {
	[self willAccessValueForKey:@"alarms"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"alarms"];

	[self didAccessValueForKey:@"alarms"];
	return result;
}

@dynamic friends;

- (NSMutableSet*)friendsSet {
	[self willAccessValueForKey:@"friends"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"friends"];

	[self didAccessValueForKey:@"friends"];
	return result;
}

@dynamic friendshipRequestReceived;

- (NSMutableSet*)friendshipRequestReceivedSet {
	[self willAccessValueForKey:@"friendshipRequestReceived"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"friendshipRequestReceived"];

	[self didAccessValueForKey:@"friendshipRequestReceived"];
	return result;
}

@dynamic friendshipRequestSent;

- (NSMutableSet*)friendshipRequestSentSet {
	[self willAccessValueForKey:@"friendshipRequestSent"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"friendshipRequestSent"];

	[self didAccessValueForKey:@"friendshipRequestSent"];
	return result;
}

@dynamic notifications;

- (NSMutableSet*)notificationsSet {
	[self willAccessValueForKey:@"notifications"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"notifications"];

	[self didAccessValueForKey:@"notifications"];
	return result;
}

@dynamic receivedMedias;

- (NSMutableSet*)receivedMediasSet {
	[self willAccessValueForKey:@"receivedMedias"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"receivedMedias"];

	[self didAccessValueForKey:@"receivedMedias"];
	return result;
}

@dynamic receivedMessages;

- (NSMutableSet*)receivedMessagesSet {
	[self willAccessValueForKey:@"receivedMessages"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"receivedMessages"];

	[self didAccessValueForKey:@"receivedMessages"];
	return result;
}

@dynamic sentMedias;

- (NSMutableSet*)sentMediasSet {
	[self willAccessValueForKey:@"sentMedias"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"sentMedias"];

	[self didAccessValueForKey:@"sentMedias"];
	return result;
}

@dynamic sentMessages;

- (NSMutableSet*)sentMessagesSet {
	[self willAccessValueForKey:@"sentMessages"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"sentMessages"];

	[self didAccessValueForKey:@"sentMessages"];
	return result;
}

@dynamic socialGraph;

@end

