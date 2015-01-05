#import "_EWSocial.h"

@interface EWSocial : _EWSocial {}

@property (nonatomic, strong) NSArray *facebookFriends;
@property (nonatomic, strong) NSArray *addressBookFriends;
@property (nonatomic, strong) NSMutableDictionary *friendshipTimeline;

+ (instancetype)newSocialForPerson:(EWPerson *)person;
@end
