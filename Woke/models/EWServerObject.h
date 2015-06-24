#import "_EWServerObject.h"
#import "EWBlockTypes.h"
#import <Parse/Parse.h>

#define kManagedObjectDeleted		@"mo_deleted"

@class EWServerObject;
typedef void (^EWManagedObjectSaveCallbackBlock)(EWServerObject *MO_on_main_thread, NSError *error);

@interface EWServerObject : _EWServerObject {}
@property (nonatomic, strong) NSMutableDictionary *syncInfo;
@property (nonatomic, strong) NSString *serverID;
// Custom logic goes here.
//@property (nonatomic) PFObject *serverObject;
- (BOOL)validate;
- (void)remove;

#pragma mark - Core Data local save
- (void)save;
@end
