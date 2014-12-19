// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWPerson.h instead.

@import CoreData;
#import "EWServerObject.h"

extern const struct EWPersonAttributes {
	__unsafe_unretained NSString *bgImage;
	__unsafe_unretained NSString *birthday;
	__unsafe_unretained NSString *cachedInfo;
	__unsafe_unretained NSString *city;
	__unsafe_unretained NSString *country;
	__unsafe_unretained NSString *email;
	__unsafe_unretained NSString *firstName;
	__unsafe_unretained NSString *gender;
	__unsafe_unretained NSString *history;
	__unsafe_unretained NSString *images;
	__unsafe_unretained NSString *lastName;
	__unsafe_unretained NSString *location;
	__unsafe_unretained NSString *preference;
	__unsafe_unretained NSString *profilePic;
	__unsafe_unretained NSString *statement;
	__unsafe_unretained NSString *username;
} EWPersonAttributes;

extern const struct EWPersonRelationships {
	__unsafe_unretained NSString *achievements;
	__unsafe_unretained NSString *activities;
	__unsafe_unretained NSString *alarms;
	__unsafe_unretained NSString *friends;
	__unsafe_unretained NSString *notifications;
	__unsafe_unretained NSString *receivedMedias;
	__unsafe_unretained NSString *receivedMessages;
	__unsafe_unretained NSString *sentMedias;
	__unsafe_unretained NSString *sentMessages;
	__unsafe_unretained NSString *socialGraph;
	__unsafe_unretained NSString *unreadMedias;
} EWPersonRelationships;

@class EWAchievement;
@class EWActivity;
@class EWAlarm;
@class EWPerson;
@class EWNotification;
@class EWMedia;
@class EWMessage;
@class EWMedia;
@class EWMessage;
@class EWSocial;
@class EWMedia;

@class NSObject;

@class NSObject;

@class NSObject;

@class NSObject;

@class NSObject;

@class NSObject;

@class NSObject;

@interface EWPersonID : EWServerObjectID {}
@end

@interface _EWPerson : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWPersonID* objectID;

@property (nonatomic, strong) id bgImage;

//- (BOOL)validateBgImage:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* birthday;

//- (BOOL)validateBirthday:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id cachedInfo;

//- (BOOL)validateCachedInfo:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* city;

//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* country;

//- (BOOL)validateCountry:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* email;

//- (BOOL)validateEmail:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* firstName;

//- (BOOL)validateFirstName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* gender;

//- (BOOL)validateGender:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id history;

//- (BOOL)validateHistory:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id images;

//- (BOOL)validateImages:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* lastName;

//- (BOOL)validateLastName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id location;

//- (BOOL)validateLocation:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id preference;

//- (BOOL)validatePreference:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id profilePic;

//- (BOOL)validateProfilePic:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* statement;

//- (BOOL)validateStatement:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* username;

//- (BOOL)validateUsername:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *achievements;

- (NSMutableSet*)achievementsSet;

@property (nonatomic, strong) NSSet *activities;

- (NSMutableSet*)activitiesSet;

@property (nonatomic, strong) NSSet *alarms;

- (NSMutableSet*)alarmsSet;

@property (nonatomic, strong) NSSet *friends;

- (NSMutableSet*)friendsSet;

@property (nonatomic, strong) NSSet *notifications;

- (NSMutableSet*)notificationsSet;

@property (nonatomic, strong) EWMedia *receivedMedias;

//- (BOOL)validateReceivedMedias:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWMessage *receivedMessages;

//- (BOOL)validateReceivedMessages:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *sentMedias;

- (NSMutableSet*)sentMediasSet;

@property (nonatomic, strong) EWMessage *sentMessages;

//- (BOOL)validateSentMessages:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWSocial *socialGraph;

//- (BOOL)validateSocialGraph:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *unreadMedias;

- (NSMutableSet*)unreadMediasSet;

@end

@interface _EWPerson (AchievementsCoreDataGeneratedAccessors)
- (void)addAchievements:(NSSet*)value_;
- (void)removeAchievements:(NSSet*)value_;
- (void)addAchievementsObject:(EWAchievement*)value_;
- (void)removeAchievementsObject:(EWAchievement*)value_;

@end

@interface _EWPerson (ActivitiesCoreDataGeneratedAccessors)
- (void)addActivities:(NSSet*)value_;
- (void)removeActivities:(NSSet*)value_;
- (void)addActivitiesObject:(EWActivity*)value_;
- (void)removeActivitiesObject:(EWActivity*)value_;

@end

@interface _EWPerson (AlarmsCoreDataGeneratedAccessors)
- (void)addAlarms:(NSSet*)value_;
- (void)removeAlarms:(NSSet*)value_;
- (void)addAlarmsObject:(EWAlarm*)value_;
- (void)removeAlarmsObject:(EWAlarm*)value_;

@end

@interface _EWPerson (FriendsCoreDataGeneratedAccessors)
- (void)addFriends:(NSSet*)value_;
- (void)removeFriends:(NSSet*)value_;
- (void)addFriendsObject:(EWPerson*)value_;
- (void)removeFriendsObject:(EWPerson*)value_;

@end

@interface _EWPerson (NotificationsCoreDataGeneratedAccessors)
- (void)addNotifications:(NSSet*)value_;
- (void)removeNotifications:(NSSet*)value_;
- (void)addNotificationsObject:(EWNotification*)value_;
- (void)removeNotificationsObject:(EWNotification*)value_;

@end

@interface _EWPerson (SentMediasCoreDataGeneratedAccessors)
- (void)addSentMedias:(NSSet*)value_;
- (void)removeSentMedias:(NSSet*)value_;
- (void)addSentMediasObject:(EWMedia*)value_;
- (void)removeSentMediasObject:(EWMedia*)value_;

@end

@interface _EWPerson (UnreadMediasCoreDataGeneratedAccessors)
- (void)addUnreadMedias:(NSSet*)value_;
- (void)removeUnreadMedias:(NSSet*)value_;
- (void)addUnreadMediasObject:(EWMedia*)value_;
- (void)removeUnreadMediasObject:(EWMedia*)value_;

@end

@interface _EWPerson (CoreDataGeneratedPrimitiveAccessors)

- (id)primitiveBgImage;
- (void)setPrimitiveBgImage:(id)value;

- (NSDate*)primitiveBirthday;
- (void)setPrimitiveBirthday:(NSDate*)value;

- (id)primitiveCachedInfo;
- (void)setPrimitiveCachedInfo:(id)value;

- (NSString*)primitiveCity;
- (void)setPrimitiveCity:(NSString*)value;

- (NSString*)primitiveCountry;
- (void)setPrimitiveCountry:(NSString*)value;

- (NSString*)primitiveEmail;
- (void)setPrimitiveEmail:(NSString*)value;

- (NSString*)primitiveFirstName;
- (void)setPrimitiveFirstName:(NSString*)value;

- (NSString*)primitiveGender;
- (void)setPrimitiveGender:(NSString*)value;

- (id)primitiveHistory;
- (void)setPrimitiveHistory:(id)value;

- (id)primitiveImages;
- (void)setPrimitiveImages:(id)value;

- (NSString*)primitiveLastName;
- (void)setPrimitiveLastName:(NSString*)value;

- (id)primitiveLocation;
- (void)setPrimitiveLocation:(id)value;

- (id)primitivePreference;
- (void)setPrimitivePreference:(id)value;

- (id)primitiveProfilePic;
- (void)setPrimitiveProfilePic:(id)value;

- (NSString*)primitiveStatement;
- (void)setPrimitiveStatement:(NSString*)value;

- (NSString*)primitiveUsername;
- (void)setPrimitiveUsername:(NSString*)value;

- (NSMutableSet*)primitiveAchievements;
- (void)setPrimitiveAchievements:(NSMutableSet*)value;

- (NSMutableSet*)primitiveActivities;
- (void)setPrimitiveActivities:(NSMutableSet*)value;

- (NSMutableSet*)primitiveAlarms;
- (void)setPrimitiveAlarms:(NSMutableSet*)value;

- (NSMutableSet*)primitiveFriends;
- (void)setPrimitiveFriends:(NSMutableSet*)value;

- (NSMutableSet*)primitiveNotifications;
- (void)setPrimitiveNotifications:(NSMutableSet*)value;

- (EWMedia*)primitiveReceivedMedias;
- (void)setPrimitiveReceivedMedias:(EWMedia*)value;

- (EWMessage*)primitiveReceivedMessages;
- (void)setPrimitiveReceivedMessages:(EWMessage*)value;

- (NSMutableSet*)primitiveSentMedias;
- (void)setPrimitiveSentMedias:(NSMutableSet*)value;

- (EWMessage*)primitiveSentMessages;
- (void)setPrimitiveSentMessages:(EWMessage*)value;

- (EWSocial*)primitiveSocialGraph;
- (void)setPrimitiveSocialGraph:(EWSocial*)value;

- (NSMutableSet*)primitiveUnreadMedias;
- (void)setPrimitiveUnreadMedias:(NSMutableSet*)value;

@end
