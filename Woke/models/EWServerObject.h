#import "_EWServerObject.h"
#import "EWBlockTypes.h"
#import <Parse/Parse.h>

#define kManagedObjectDeleted		@"mo_deleted"

@class EWServerObject;
typedef void (^EWManagedObjectSaveCallbackBlock)(EWServerObject *MO_on_main_thread, NSError *error);

@interface EWServerObject : _EWServerObject {}
@property (nonatomic, strong) NSMutableDictionary *syncInfo;
// Custom logic goes here.
//@property (nonatomic) PFObject *serverObject;
- (BOOL)validate;
- (void)remove;
- (NSString *)serverID;

#pragma mark - Core Data local save
- (void)save;
@end
