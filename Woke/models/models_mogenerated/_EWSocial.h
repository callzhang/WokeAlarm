// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWSocial.h instead.

@import CoreData;
#import "EWServerObject.h"

extern const struct EWSocialAttributes {
	__unsafe_unretained NSString *addressBookFriends;
	__unsafe_unretained NSString *addressBookRelatedUsers;
	__unsafe_unretained NSString *addressBookUpdated;
	__unsafe_unretained NSString *facebookFriends;
	__unsafe_unretained NSString *facebookID;
	__unsafe_unretained NSString *facebookRelatedUsers;
	__unsafe_unretained NSString *facebookToken;
	__unsafe_unretained NSString *facebookUpdated;
	__unsafe_unretained NSString *friendshipTimeline;
} EWSocialAttributes;

extern const struct EWSocialRelationships {
	__unsafe_unretained NSString *owner;
} EWSocialRelationships;

@class EWPerson;

@class NSObject;

@class NSObject;

@class NSObject;

@class NSObject;

@class NSObject;

@interface EWSocialID : EWServerObjectID {}
@end

@interface _EWSocial : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWSocialID* objectID;

@property (nonatomic, strong) id addressBookFriends;

//- (BOOL)validateAddressBookFriends:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id addressBookRelatedUsers;

//- (BOOL)validateAddressBookRelatedUsers:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* addressBookUpdated;

//- (BOOL)validateAddressBookUpdated:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id facebookFriends;

//- (BOOL)validateFacebookFriends:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* facebookID;

//- (BOOL)validateFacebookID:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id facebookRelatedUsers;

//- (BOOL)validateFacebookRelatedUsers:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* facebookToken;

//- (BOOL)validateFacebookToken:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* facebookUpdated;

//- (BOOL)validateFacebookUpdated:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id friendshipTimeline;

//- (BOOL)validateFriendshipTimeline:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;

@end

@interface _EWSocial (CoreDataGeneratedPrimitiveAccessors)

- (id)primitiveAddressBookFriends;
- (void)setPrimitiveAddressBookFriends:(id)value;

- (id)primitiveAddressBookRelatedUsers;
- (void)setPrimitiveAddressBookRelatedUsers:(id)value;

- (NSDate*)primitiveAddressBookUpdated;
- (void)setPrimitiveAddressBookUpdated:(NSDate*)value;

- (id)primitiveFacebookFriends;
- (void)setPrimitiveFacebookFriends:(id)value;

- (NSString*)primitiveFacebookID;
- (void)setPrimitiveFacebookID:(NSString*)value;

- (id)primitiveFacebookRelatedUsers;
- (void)setPrimitiveFacebookRelatedUsers:(id)value;

- (NSData*)primitiveFacebookToken;
- (void)setPrimitiveFacebookToken:(NSData*)value;

- (NSDate*)primitiveFacebookUpdated;
- (void)setPrimitiveFacebookUpdated:(NSDate*)value;

- (id)primitiveFriendshipTimeline;
- (void)setPrimitiveFriendshipTimeline:(id)value;

- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;

@end
