#import "_EWActivity.h"

@interface EWActivity : _EWActivity {}
@property (nonatomic, strong) NSArray *mediaIDs;

// add
+ (EWActivity *)newActivity;

// search
+ (EWActivity *)getActivityWithID:(NSString *)ID;
- (NSArray *)medias;
// valid
- (BOOL)validate;

- (void)addMediaIDs:(NSArray *)serverIDs;
@end
