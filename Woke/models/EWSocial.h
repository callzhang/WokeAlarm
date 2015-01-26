#import "_EWSocial.h"

@interface EWSocial : _EWSocial {}

@property (nonatomic, strong) NSMutableArray *facebookFriends;
@property (nonatomic, strong) NSMutableArray *addressBookFriends;
@property (nonatomic, strong) NSMutableDictionary *friendshipTimeline;

+ (instancetype)newSocialForPerson:(EWPerson *)person;
+ (instancetype)getSocialByID:(NSString *)socialID;
@end
