#import "_EWActivity.h"


extern const struct EWActivityTypes {
    __unsafe_unretained NSString *media;//sending media
    __unsafe_unretained NSString *friendship;//friendship
    __unsafe_unretained NSString *alarm;//alarm timer
} EWActivityTypes;

@interface EWActivity : _EWActivity {}
@property (nonatomic, strong) NSArray *mediaIDs;

// add
+ (EWActivity *)newActivity;
// delete
- (void)remove;
// search
+ (EWActivity *)getActivityWithID:(NSString *)ID;
// valid
- (BOOL)validate;

- (void)addMediaID:(NSString *)objectID;

- (EWActivity *)createWithPerson:(EWPerson *)person friended:(BOOL)friended;
@end
