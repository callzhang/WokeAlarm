#import "_EWMedia.h"

#define kMediaTypeVoice     @"voice"

extern const struct EWMediaEmoji {
    __unsafe_unretained NSString *smile;
    __unsafe_unretained NSString *sad;
    __unsafe_unretained NSString *heart;
    __unsafe_unretained NSString *tear;
    __unsafe_unretained NSString *kiss;
} EWMediaEmoji;

NSString *imageAssetNameFromEmoji(NSString *emoji);

@interface EWMedia : _EWMedia

//new
+ (EWMedia *)newMedia;
//search
+ (EWMedia *)getMediaByID:(NSString *)mediaID;
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
