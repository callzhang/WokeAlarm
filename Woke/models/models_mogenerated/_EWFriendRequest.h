// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWFriendRequest.h instead.

@import CoreData;
#import "EWServerObject.h"

extern const struct EWFriendRequestAttributes {
	__unsafe_unretained NSString *status;
} EWFriendRequestAttributes;

extern const struct EWFriendRequestRelationships {
	__unsafe_unretained NSString *receiver;
	__unsafe_unretained NSString *sender;
} EWFriendRequestRelationships;

@class EWPerson;
@class EWPerson;

@interface EWFriendRequestID : EWServerObjectID {}
@end

@interface _EWFriendRequest : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWFriendRequestID* objectID;

@property (nonatomic, strong) NSString* status;

//- (BOOL)validateStatus:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *receiver;

//- (BOOL)validateReceiver:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EWPerson *sender;

//- (BOOL)validateSender:(id*)value_ error:(NSError**)error_;

@end

@interface _EWFriendRequest (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveStatus;
- (void)setPrimitiveStatus:(NSString*)value;

- (EWPerson*)primitiveReceiver;
- (void)setPrimitiveReceiver:(EWPerson*)value;

- (EWPerson*)primitiveSender;
- (void)setPrimitiveSender:(EWPerson*)value;

@end
