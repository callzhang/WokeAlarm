#import "_EWServerObject.h"

@interface EWServerObject : _EWServerObject {}
// Custom logic goes here.
//@property (nonatomic) PFObject *serverObject;
- (BOOL)validate;
- (NSString *)serverID;
/**
 *  Upload to server immediately
 *
 *  @param block Passing EWServerObject's counterparty - PFObject back to the block
 */
- (void)updateToServerWithCompletion:(void (^)(PFObject *PO))block;
@end
