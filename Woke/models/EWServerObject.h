#import "_EWServerObject.h"

@interface EWServerObject : _EWServerObject {}
// Custom logic goes here.
//@property (nonatomic) PFObject *serverObject;
- (BOOL)validate;
- (void)remove;
- (NSString *)serverID;
/**
 *  Upload to server immediately
 *
 *  @param block Passing EWServerObject's counterparty - PFObject back to the block
 */
- (void)updateToServerWithCompletion:(PFObjectResultBlock)block;
- (NSString *)serverClassName;

@end
