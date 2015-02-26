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
- (void)save;
- (void)saveWithCompletion:(BoolErrorBlock)block;
/**
 *  Upload to server immediately
 *
 *  @param block Passing EWServerObject's counterparty - PFObject back to the block
 */
- (void)updateToServerWithCompletion:(EWManagedObjectSaveCallbackBlock)block;
- (NSString *)serverClassName;

/**
 *  The owner of this object, used to determine if we need to fully download the object or upload this object to server.
 *  @attention EWPerson will return itself
 *  @return Owner
 */
- (EWServerObject *)ownerObject;
@end
