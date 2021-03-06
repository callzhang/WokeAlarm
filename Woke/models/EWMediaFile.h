#import "_EWMediaFile.h"

@interface EWMediaFile : _EWMediaFile {}
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIImage *thumbnail;
@property (nonatomic, retain) NSString *audioKey;

+ (EWMediaFile *)newMediaFile;
//- (void)remove;
+ (EWMediaFile *)getMediaFileByID:(NSString *)ID error:(NSError **)error;

@end
