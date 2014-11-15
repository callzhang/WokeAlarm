// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWSocial.h instead.

#import <CoreData/CoreData.h>
#import "EWServerObject.h"

extern const struct EWSocialAttributes {
	__unsafe_unretained NSString *facebookFriends;
	__unsafe_unretained NSString *facebookToken;
	__unsafe_unretained NSString *facebookUpdated;
	__unsafe_unretained NSString *weiboFriends;
	__unsafe_unretained NSString *weiboToken;
	__unsafe_unretained NSString *weiboUpdated;
} EWSocialAttributes;

extern const struct EWSocialRelationships {
	__unsafe_unretained NSString *owner;
} EWSocialRelationships;

@class EWPerson;

@class NSObject;

@class NSObject;

@interface EWSocialID : EWServerObjectID {}
@end

@interface _EWSocial : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWSocialID* objectID;

@property (nonatomic, strong) id facebookFriends;

//- (BOOL)validateFacebookFriends:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* facebookToken;

//- (BOOL)validateFacebookToken:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* facebookUpdated;

//- (BOOL)validateFacebookUpdated:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id weiboFriends;

//- (BOOL)validateWeiboFriends:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* weiboToken;

//- (BOOL)validateWeiboToken:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* weiboUpdated;

//- (BOOL)validateWeiboUpdated:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;

@end

@interface _EWSocial (CoreDataGeneratedPrimitiveAccessors)

- (id)primitiveFacebookFriends;
- (void)setPrimitiveFacebookFriends:(id)value;

- (NSData*)primitiveFacebookToken;
- (void)setPrimitiveFacebookToken:(NSData*)value;

- (NSDate*)primitiveFacebookUpdated;
- (void)setPrimitiveFacebookUpdated:(NSDate*)value;

- (id)primitiveWeiboFriends;
- (void)setPrimitiveWeiboFriends:(id)value;

- (NSData*)primitiveWeiboToken;
- (void)setPrimitiveWeiboToken:(NSData*)value;

- (NSDate*)primitiveWeiboUpdated;
- (void)setPrimitiveWeiboUpdated:(NSDate*)value;

- (EWPerson*)primitiveOwner;
- (void)setPrimitiveOwner:(EWPerson*)value;

@end
