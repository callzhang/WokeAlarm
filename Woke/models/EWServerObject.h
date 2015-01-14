#import "_EWServerObject.h"

@interface EWServerObject : _EWServerObject {}
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
- (void)updateToServerWithCompletion:(PFObjectResultBlock)block;
- (NSString *)serverClassName;

/**
 *  The owner of this object, used to determine if we need to fully download the object or upload this object to server.
 *  @attention EWPerson will return itself
 *  @return Owner
 */
- (EWServerObject *)ownerObject;
@end
