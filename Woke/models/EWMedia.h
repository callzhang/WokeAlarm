#import "_EWMedia.h"

#define kMediaTypeVoice     @"voice"

extern const struct EWMediaEmoji {
    __unsafe_unretained NSString *smile;
    __unsafe_unretained NSString *sad;
    __unsafe_unretained NSString *heart;
    __unsafe_unretained NSString *tear;
    __unsafe_unretained NSString *kiss;
} EWMediaEmoji;

extern NSString *imageAssetNameFromEmoji(NSString *emoji);
extern NSString *borderlessImageAssetNameFromEmoji(NSString *emoji);
extern NSString *emojiNameFromImageAssetName(NSString *name);

@interface EWMedia : _EWMedia

//new
+ (EWMedia *)newMedia;
//search
+ (EWMedia *)getMediaByID:(NSString *)mediaID;
+ (EWMedia *)getMediaByID:(NSString *)mediaID inContext:(NSManagedObjectContext *)context;

//validate
- (BOOL)validate;
//ACL
- (void)createACL;
//download
- (void)downloadMediaFile;
- (void)downloadMediaFileWithCompletion:(BoolErrorBlock)block;

//data
- (NSData *)audio;
- (NSString *)audioKey;
@end
