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

// search
+ (EWActivity *)getActivityWithID:(NSString *)ID;
- (NSArray *)medias;
// valid
- (BOOL)validate;

- (void)addMediaID:(NSString *)serverID;

- (EWActivity *)createWithPerson:(EWPerson *)person friended:(BOOL)friended;
@end
