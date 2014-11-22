#import "_EWActivity.h"


extern const struct EWActivityTypes {
    __unsafe_unretained NSString *media;//sending media
    __unsafe_unretained NSString *friendship;//friendship
    __unsafe_unretained NSString *alarm;//alarm timer
} EWActivityTypes;

@interface EWActivity : _EWActivity {}
// add
+ (EWActivity *)newActivity;
// delete
- (void)remove;
// search
//+ (EWActivity *)findActivityWithID:(NSString *)ID;
// valid
- (BOOL)validate;

- (EWActivity *)createWithMedia:(EWMedia *)media;
- (EWActivity *)createWithPerson:(EWPerson *)person friended:(BOOL)friended;
@end
