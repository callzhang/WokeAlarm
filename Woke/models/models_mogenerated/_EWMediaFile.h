// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EWMediaFile.h instead.

@import CoreData;
#import "EWServerObject.h"

extern const struct EWMediaFileAttributes {
	__unsafe_unretained NSString *audio;
	__unsafe_unretained NSString *image;
	__unsafe_unretained NSString *owner;
	__unsafe_unretained NSString *thumbnail;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *video;
} EWMediaFileAttributes;

extern const struct EWMediaFileRelationships {
	__unsafe_unretained NSString *medias;
} EWMediaFileRelationships;

@class EWMedia;

@class NSObject;

@class NSObject;

@interface EWMediaFileID : EWServerObjectID {}
@end

@interface _EWMediaFile : EWServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EWMediaFileID* objectID;

@property (nonatomic, strong) NSData* audio;

//- (BOOL)validateAudio:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id image;

//- (BOOL)validateImage:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) id thumbnail;

//- (BOOL)validateThumbnail:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* title;

//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSData* video;

//- (BOOL)validateVideo:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *medias;

- (NSMutableSet*)mediasSet;

@end

@interface _EWMediaFile (MediasCoreDataGeneratedAccessors)
- (void)addMedias:(NSSet*)value_;
- (void)removeMedias:(NSSet*)value_;
- (void)addMediasObject:(EWMedia*)value_;
- (void)removeMediasObject:(EWMedia*)value_;

@end

@interface _EWMediaFile (CoreDataGeneratedPrimitiveAccessors)

- (NSData*)primitiveAudio;
- (void)setPrimitiveAudio:(NSData*)value;

- (id)primitiveImage;
- (void)setPrimitiveImage:(id)value;

- (NSString*)primitiveOwner;
- (void)setPrimitiveOwner:(NSString*)value;

- (id)primitiveThumbnail;
- (void)setPrimitiveThumbnail:(id)value;

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (NSData*)primitiveVideo;
- (void)setPrimitiveVideo:(NSData*)value;

- (NSMutableSet*)primitiveMedias;
- (void)setPrimitiveMedias:(NSMutableSet*)value;

@end
