#import "_EWSocial.h"

@interface EWSocial : _EWSocial {}

@property (nonatomic, strong) NSMutableDictionary *facebookFriends;
@property (nonatomic, strong) NSMutableArray *facebookRelatedUsers
@property (nonatomic, strong) NSMutableDictionary *addressBookFriends;
@property (nonatomic, strong) NSMutableArray *addressBookRelatedUsers;
@property (nonatomic, strong) NSMutableDictionary *friendshipTimeline;

+ (instancetype)newSocialForPerson:(EWPerson *)person;
+ (instancetype)getSocialByID:(NSString *)socialID;
@end
