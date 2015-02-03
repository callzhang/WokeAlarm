#import "_EWSocial.h"

@interface EWSocial : _EWSocial {}

@property (nonatomic, strong) NSMutableDictionary *facebookFriends;//stores facebook friends ID and Name
@property (nonatomic, strong) NSMutableArray *facebookRelatedUsers;//stores woke users that match with my facebook ID
@property (nonatomic, strong) NSMutableArray *addressBookFriends;//Array of {“email”: email, “name”: name}
@property (nonatomic, strong) NSMutableArray *addressBookRelatedUsers;//woke users that match contact emails
@property (nonatomic, strong) NSMutableDictionary *friendshipTimeline;

+ (instancetype)newSocialForPerson:(EWPerson *)person;
+ (instancetype)getSocialByID:(NSString *)socialID;
@end
