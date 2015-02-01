#import "EWMedia.h"
#import "EWMediaFile.h"
#import "AssetCatalogIdentifiers.h"

const struct EWMediaEmoji EWMediaEmoji = {
    .smile = @"[SMILE]",
    .kiss = @"[KISS]",
    .sad = @"[SAD]",
    .heart = @"[HEART]",
    .tear = @"[TEAR]",
};

NSString *imageAssetNameFromEmoji(NSString *emoji) {
    if ([emoji isEqualToString:EWMediaEmoji.smile]) {
        return [ImagesCatalog wokeResponseIconSmileNormalName];
    }
    if ([emoji isEqualToString:EWMediaEmoji.kiss]) {
        return [ImagesCatalog wokeResponseIconKissNormalName];
    }
    if ([emoji isEqualToString:EWMediaEmoji.sad]) {
        return [ImagesCatalog wokeResponseIconSadNormalName];
    }
    if ([emoji isEqualToString:EWMediaEmoji.heart]) {
        return [ImagesCatalog wokeResponseIconHeartNormalName];
    }
    if ([emoji isEqualToString:EWMediaEmoji.tear]) {
        return [ImagesCatalog wokeResponseIconTearNormalName];
    }
    return @"";
};

@interface EWMedia ()

// Private interface goes here.

@end

@implementation EWMedia

#pragma mark - create media
+ (EWMedia *)newMedia{
    EWAssertMainThread
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
    if (!media || !media.updatedAt) {
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

- (void)downloadMediaFileWithCompletion:(BoolErrorBlock)block{
    EWMediaFile *file = self.mediaFile;
	BOOL good = self.mediaFile.audio != nil;
    if (!file) {
        [self refreshInBackgroundWithCompletion:^(NSError *error){
            [self.mediaFile refreshInBackgroundWithCompletion:^(NSError *err){
				BOOL hasFile = self.mediaFile.audio != nil;
				BOOL changed = good != hasFile;
                if (block) {
                    block(changed,err);
                }
            }];
        }];
    }else if(!file.audio){
        [file refreshInBackgroundWithCompletion:^(NSError *error){
            if (block) {
				BOOL hasFile = self.mediaFile.audio != nil;
				BOOL changed = good != hasFile;
                block(changed, error);
            }
        }];
    }
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

- (EWServerObject *)ownerObject{
    return self.author;
}
@end
