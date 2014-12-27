#import "EWMedia.h"
#import "EWMediaFile.h"

@interface EWMedia ()

// Private interface goes here.

@end

@implementation EWMedia

#pragma mark - create media
+ (EWMedia *)newMedia{
    NSParameterAssert([NSThread isMainThread]);
    EWMedia *m = [EWMedia MR_createEntity];
    m.updatedAt = [NSDate date];
    m.author = [EWPerson me];
    return m;
}


#pragma mark - validate
- (BOOL)validate{
    BOOL good = YES;
    if(!self.type){
        good = NO;
    }
    
    if (!self.author) {
        DDLogError(@"Media %@ missing authur.", self.objectId);
        good = NO;
    }
    
    if ([self.type isEqualToString:kMediaTypeVoice]) {
        if(!self.mediaFile){
            DDLogError(@"Media %@ type voice with no mediaFile.", self.objectId);
            good = NO;
        }
    }
    
    if (!self.receiver) {
        DDLogError(@"Media %@ with no receiver.", self.objectId);
        good = NO;
    }
    
    return good;
}

- (void)createACL{
    PFObject *m = self.parseObject;
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    PFObject *PO = self.receiver.parseObject;
    [acl setReadAccess:YES forUser:(PFUser *)PO];
    [acl setReadAccess:YES forUser:(PFUser *)PO];
    m.ACL = acl;
    DDLogVerbose(@"ACL created for media(%@) with access for %@", self.objectId, self.receiver.serverID);
}

+ (EWMedia *)getMediaByID:(NSString *)mediaID{
    return [[self class] getMediaByID:mediaID inContext:mainContext];
}

+ (EWMedia *)getMediaByID:(NSString *)mediaID inContext:(NSManagedObjectContext *)context{
    EWMedia *media = [EWMedia MR_findByAttribute:kParseObjectID withValue:mediaID inContext:context].firstObject;
    if (!media) {
        //need to find it on server
        NSError *error;
        media = (EWMedia *)[EWSync findObjectWithClass:NSStringFromClass([EWMedia class]) withID:mediaID inContext:context error:&error];
        
        //download media
        NSLog(@"Downloading media: %@", media.objectId);
        [media downloadMediaFile];
        
        //post notification
        if ([NSThread isMainThread]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:media];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                EWMedia *m = [media MR_inContext:mainContext];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNewMediaNotification object:m];
            });
        }
    }
    return media;
}


#pragma mark - Media File
- (void)downloadMediaFile{
    EWMediaFile *file = self.mediaFile;
    if (!file) {
        [self refresh];
        file = self.mediaFile;
    }
    [file refresh];
}

- (void)downloadMediaFileWithCompletion:(ErrorBlock)block{
    EWMediaFile *file = self.mediaFile;
    if (!file) {
        [self refreshInBackgroundWithCompletion:^(NSError *error){
            [self.mediaFile refreshInBackgroundWithCompletion:^(NSError *err){
                if (block) {
                    block(err);
                }
            }];
        }];
    }else{
        [file refreshInBackgroundWithCompletion:^(NSError *error){
            if (block) {
                block(error);
            }
        }];
    }
}

#pragma mark - DELETE
- (void)remove{
    [self MR_deleteEntity];
    [EWSync save];
}

#pragma mark - Underlying data
- (NSData *)audio{
    //TODO
    return nil;
}

- (NSString *)audioKey{
    //TODO
    return nil;
}
@end
