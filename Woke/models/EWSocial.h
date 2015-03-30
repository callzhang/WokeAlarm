#import "_EWSocial.h"

@interface EWSocial : _EWSocial {}

@property (nonatomic, strong) NSMutableDictionary *facebookFriends;//stores facebook friends as {ID: Name}
//@property (nonatomic, strong) NSMutableArray *facebookRelatedUsers;//stores woke users that match with facebook ID in facebookFriends
@property (nonatomic, strong) NSMutableArray *addressBookFriends;//Array of {“email”: email, “name”: name}
@property (nonatomic, strong) NSMutableArray *addressBookRelatedUsers;//woke user emails that matches email in addressBookFriends
@property (nonatomic, strong) NSMutableDictionary *friendshipTimeline;

+ (instancetype)newSocialForPerson:(EWPerson *)person;
+ (instancetype)getSocialByID:(NSString *)socialID error:(NSError **)error;
@end
