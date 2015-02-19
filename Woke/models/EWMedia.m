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
    return nil;
};

NSString *borderlessImageAssetNameFromEmoji(NSString *emoji) {
    if ([emoji isEqualToString:EWMediaEmoji.smile]) {
        return [ImagesCatalog wokeResponseIconSmileBorderlessName];
    }
    if ([emoji isEqualToString:EWMediaEmoji.kiss]) {
        return [ImagesCatalog wokeResponseIconKissBorderlessName];
    }
    if ([emoji isEqualToString:EWMediaEmoji.sad]) {
        return [ImagesCatalog wokeResponseIconSadBorderlessName];
    }
    if ([emoji isEqualToString:EWMediaEmoji.heart]) {
        return [ImagesCatalog wokeResponseIconHeartBorderlessName];
    }
    if ([emoji isEqualToString:EWMediaEmoji.tear]) {
        return [ImagesCatalog wokeResponseIconTearBorderlessName];
    }
    return nil;
};

NSString *emojiNameFromImageAssetName(NSString *name) {
    if ([name isEqualToString:[ImagesCatalog wokeResponseIconSmileNormalName]] ||
        [name isEqualToString:[ImagesCatalog wokeResponseIconSmileHighlightedName]] ||
         [name isEqualToString:[ImagesCatalog wokeResponseIconSmileBorderlessName]] ) {
        return EWMediaEmoji.smile;
    }
    
    if ([name isEqualToString:[ImagesCatalog wokeResponseIconKissNormalName]] ||
        [name isEqualToString:[ImagesCatalog wokeResponseIconKissHighlightedName]] ||
        [name isEqualToString:[ImagesCatalog wokeResponseIconKissBorderlessName]] ) {
        return EWMediaEmoji.kiss;
    }
    
    if ([name isEqualToString:[ImagesCatalog wokeResponseIconSadNormalName]] ||
        [name isEqualToString:[ImagesCatalog wokeResponseIconSadHighlightedName]] ||
        [name isEqualToString:[ImagesCatalog wokeResponseIconSadBorderlessName]] ) {
        return EWMediaEmoji.sad;
    }
    
    if ([name isEqualToString:[ImagesCatalog wokeResponseIconHeartNormalName]] ||
        [name isEqualToString:[ImagesCatalog wokeResponseIconHeartHighlightedName]] ||
        [name isEqualToString:[ImagesCatalog wokeResponseIconHeartBorderlessName]] ) {
        return EWMediaEmoji.heart;
    }
    
    if ([name isEqualToString:[ImagesCatalog wokeResponseIconTearNormalName]] ||
        [name isEqualToString:[ImagesCatalog wokeResponseIconTearHighlightedName]] ||
        [name isEqualToString:[ImagesCatalog wokeResponseIconTearBorderlessName]] ) {
        return EWMediaEmoji.tear;
    }

//    if ([name isEqualToString:[ImagesCatalog wokeResponseIconReplyNormalName]] ||
//        [name isEqualToString:[ImagesCatalog wokeResponseIconReplyHighlightedName]]) {
//    }
    return nil;
}

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
        DDLogError(@"Media %@ missing type.", self.serverID);
        good = NO;
    }
    
    if (!self.author) {
        DDLogError(@"Media %@ missing authur.", self.serverID);
        good = NO;
    }
    
    if ([self.type isEqualToString:kMediaTypeVoice]) {
        if(!self.mediaFile){
            DDLogError(@"Media %@ type voice with no mediaFile.", self.serverID);
            good = NO;
        }
    }
    
    if (!self.receiver) {
        DDLogError(@"Media %@ with no receiver.", self.serverID);
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
    EWAssertMainThread
    return [[self class] getMediaByID:mediaID inContext:mainContext];
}

+ (EWMedia *)getMediaByID:(NSString *)mediaID inContext:(NSManagedObjectContext *)context{
	PFObject *mediaPO = [[EWSync sharedInstance] getParseObjectWithClass:NSStringFromClass([EWMedia class]) ID:mediaID error:nil];
    EWMedia *media = (EWMedia *)[mediaPO managedObjectInContext:context option:EWSyncOptionUpdateRelation completion:nil];
	[media downloadMediaFile];

	if (![media validate]) {
		DDLogError(@"Get new media but not valid: %@", media);
		return nil;
	}
    return media;
}


#pragma mark - Media File
- (void)downloadMediaFile{
	EWMediaFile *file = self.mediaFile;
	BOOL good = self.mediaFile.audio != nil;
	if (!file) {
		PFObject *filePO = self.parseObject[EWMediaRelationships.mediaFile];
		[filePO fetchIfNeeded];
		file = (EWMediaFile *)[filePO managedObjectInContext:self.managedObjectContext option:EWSyncOptionUpdateRelation completion:nil];
		if (![file validate]) {
			DDLogError(@"Failed to download media file: %@", file);
		}
	}else if(!file.audio){
		[file refresh];
	}
}

- (void)downloadMediaFileWithCompletion:(BoolErrorBlock)block{
    EWMediaFile *file = self.mediaFile;
	BOOL good = self.mediaFile.audio != nil;
    if (!file) {
        PFObject *filePO = self.parseObject[EWMediaRelationships.mediaFile];
        [filePO fetchIfNeeded];
        [filePO managedObjectInContext:self.managedObjectContext option:EWSyncOptionUpdateAsync completion:^(EWServerObject *SO, NSError *error) {
            BOOL hasFile = self.mediaFile.audio != nil;
            if (block) {
                block(hasFile,error);
            }
        }];
    }else if(!file.audio){
        [file refreshInBackgroundWithCompletion:^(NSError *error){
            if (block) {
				BOOL hasFile = self.mediaFile.audio != nil;
                block(hasFile, error);
            }
        }];
    }else{
        if (block) {
            block(good, nil);
        }
    }
}

#pragma mark - Underlying data
- (NSData *)audio{
    return self.mediaFile.audio;
}

- (NSString *)audioKey{
    return self.mediaFile.audioKey;
}

- (EWServerObject *)ownerObject{
    return self.author;
}
@end
