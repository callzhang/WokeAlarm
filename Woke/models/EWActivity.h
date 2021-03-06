#import "_EWActivity.h"

@interface EWActivity : _EWActivity {}
@property (nonatomic, strong) NSMutableArray *mediaIDs;

// add
+ (EWActivity *)newActivity;

// search
+ (EWActivity *)getActivityWithID:(NSString *)ID error:(NSError **)error;
- (NSArray *)medias;
// valid
- (BOOL)validate;

- (void)addMediaIDs:(NSArray *)serverIDs;
@end
