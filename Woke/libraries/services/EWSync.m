//
//  EWSync.m
//  Woke
//
//  Created by Lee on 9/24/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWSync.h"
#import "EWUIUtil.h"
#import "EWServerObject.h"
#import "AFNetworkReachabilityManager.h"
#import "NSDictionary+KeyPathAccess.h"
#import "EWErrorManager.h"
#import "FBKVOController.h"
#import "NSTimer+BlocksKit.h"
#import "EWUtil.h"

NSString * const kEWSyncUploaded = @"sync_uploaded";

//============ Global shortcut to main context ===========
NSManagedObjectContext *mainContext;
//=======================================================


//Parse update queue
#define kParseQueueInsert                   @"parse_queue_insert"
#define kParseQueueUpdate                   @"parse_queue_update"
#define kParseQueueDelete                   @"parse_queue_delete"
#define kParseQueueWorking                  @"parse_queue_working"
#define kParseQueueDownload                 @"parse_queue_refresh"//queue for refresh/download
#define kChangedRecords						@"changed_records"

@interface EWSync()
@property (nonatomic, strong) NSManagedObjectContext *context; //the main context(private)
@property (strong) NSMutableDictionary *parseSaveCallbacks;
@property (nonatomic, strong) NSTimer *saveToServerDelayTimer;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachability;
/**
 *  Dictionary of {MO_ObjectID, ARRAY of EWManagedObjectSaveBlocks}
 *  EWManagedObjectSaveCallbackBlock takes two parameters: MO_main_thread and NSError
 */
@property (strong) NSMutableDictionary *uploadCompletionCallbacks;
/**
 * A dictionary holds pairs of {serverID: class name};
 * use dictionary so it can be saved to UserDefaults
 */
@property (atomic, strong) NSMutableDictionary *managedObjectsUpdating;
@end


@implementation EWSync
@synthesize parseSaveCallbacks;
@synthesize changedRecords = _changedRecords;
@synthesize isUploading = _isUploading;

+ (EWSync *)sharedInstance{
    
    static EWSync *sharedInstance_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance_ = [[EWSync alloc] init];
    });
    return sharedInstance_;
}

- (void)setup{
    
    //Access Control: enable public read access while disabling public write access.
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    //core data
    [MagicalRecord setupCoreDataStack];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelWarn];
    _context = [NSManagedObjectContext MR_defaultContext];
    mainContext = _context;
    
    //observe context change to update the modifiedData of that MO. (Only observe the main context)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preSaveAction:) name:NSManagedObjectContextWillSaveNotification object:_context];
    
    
    //Observe background context saves so main context can perform upload
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:_context queue:nil usingBlock:^(NSNotification *note) {
        [_saveToServerDelayTimer invalidate];
        _saveToServerDelayTimer = [NSTimer scheduledTimerWithTimeInterval:kUploadLag target:self selector:@selector(uploadToServer) userInfo:nil repeats:NO];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:EWAccountDidLogoutNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kParseQueueDownload];
    }];
    
    //Reachability
    self.reachability = [AFNetworkReachabilityManager sharedManager];
    [self.reachability startMonitoring];
    [self.reachability setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status != 0) {
            //[EWUIUtil showSuccessHUBWithString:@"Online"];
            if (![EWSession sharedSession].isSyncingUser) {
                DDLogDebug(@"====== Network is reachable. Start upload. ======");
                //in background thread
                [[EWSync sharedInstance] resumeUploadToServer];
                
                //resume refresh MO
                NSSet *MOs = [[EWSync sharedInstance] getObjectFromQueue:kParseQueueDownload].copy;
                [[EWSync sharedInstance] clearQueue:kParseQueueDownload];
                for (EWServerObject *MO in MOs) {
                    [MO refreshInBackgroundWithCompletion:^(NSError *error){
                        DDLogInfo(@"%@(%@) refreshed after network resumed: %@", MO.entity.name, MO.serverID, error.description);
                    }];
                }
            }
            
        } else {
            [EWUIUtil showWarningHUBWithString:@"Offline"];
            DDLogInfo(@"====== Network is unreachable ======");
        }
        
    }];
    
    //initial property
    self.parseSaveCallbacks = [NSMutableDictionary dictionary];
    self.uploadCompletionCallbacks = [NSMutableDictionary new];
    self.managedObjectsUpdating = [NSMutableDictionary new];
}


#pragma mark - connectivity
+ (BOOL)isReachable{
    return [EWSync sharedInstance].isReachable;
}

- (BOOL)isReachable{
    return !self.reachability.networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable;
}

+ (void)addToUpdatingMarks:(EWServerObject *)SO{
    [EWSync sharedInstance].managedObjectsUpdating[SO.serverID] = SO.entity.name;
}

+ (BOOL)isUpdating:(EWServerObject *)SO {
    NSString *class = [EWSync sharedInstance].managedObjectsUpdating[SO.serverID];
    return class != nil;
}

+ (void)removeMOFromUpdating:(EWServerObject *)SO{
    [[EWSync sharedInstance].managedObjectsUpdating removeObjectForKey:SO.serverID];
}

+ (BOOL)isDownloading:(EWServerObject *)SO{
    if ([[EWSync sharedInstance] contains:SO inQueue:kParseQueueDownload]) {
        DDLogInfo(@"EWSync is downloading %@(%@)", SO.entity.name, SO.serverID);
        return YES;
    }
    return NO;
}

+ (BOOL)isInUpdatingQueue:(EWServerObject *)SO {
    if ([[EWSync sharedInstance] contains:SO inQueue:kParseQueueInsert] ||
        [[EWSync sharedInstance] contains:SO inQueue:kParseQueueUpdate] ||
        [[EWSync sharedInstance] contains:SO inQueue:kParseQueueWorking]) {
        return YES;
    }
    return NO;
}

#pragma mark - ============== Parse Server methods ==============
+ (void)saveImmediately{
    //trigger save immediately
    if ([NSThread isMainThread]) {
        //upload immediately
        [[EWSync sharedInstance] uploadToServer];
    } else {
        //delay 1s so the save action could be completed
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[EWSync sharedInstance] uploadToServer];
        });
    }
}


- (BOOL)isUploading{
    return _isUploading;
}

- (void)setIsUploading:(BOOL)isUploading{
    @synchronized(self){
        _isUploading = isUploading;
    }
}
#pragma mark -
- (void)uploadToServer{
    //make sure it is called on main thread
    EWAssertMainThread
    if (self.reachability.networkReachabilityStatus <= AFNetworkReachabilityStatusNotReachable) {
        DDLogInfo(@"Network not reachable, abroad uploading");
        return;
    }
    
    if([mainContext hasChanges]){
        DDLogDebug(@"There is still some change, save and upload later");
        [mainContext MR_saveToPersistentStoreAndWait];
        return;
    }
    
    if ([self workingQueue].count >0 && self.isUploading) {
        DDLogWarn(@"Data Store is uploading, delay for 10s: %@", self.updatingClassAndValues);
        static NSTimer *uploadDelay;
        [uploadDelay invalidate];
        uploadDelay = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(uploadToServer) userInfo:nil repeats:NO];
        return;
    }
    self.isUploading = YES;
    
    //determin network reachability
    if (!self.isReachable) {
        DDLogDebug(@"Network not reachable, skip uploading");
        self.isUploading = NO;
        [self runAllManagedObjectSavingCompletionBlocksWithError:[EWErrorManager noInternetConnectError]];
        return;
    }
    
    //only ManagedObjectID is thread safe
    NSSet *insertedManagedObjects = [self insertQueue];
    NSSet *updatedManagedObjects = [self updateQueue];
    NSSet *deletedServerObjects = self.deleteQueue;
    
    //copy the list to working queue
    for (EWServerObject *mo in insertedManagedObjects) [self appendObject:mo toQueue:kParseQueueWorking];
    for (EWServerObject *mo in updatedManagedObjects) [self appendObject:mo toQueue:kParseQueueWorking];
    //clear queues
    [self clearQueue:kParseQueueInsert];
    [self clearQueue:kParseQueueUpdate];
	
    //skip if no changes
    NSSet *workingObjects = self.workingQueue.copy;
    if (workingObjects.count == 0 && deletedServerObjects.count == 0){
        DDLogInfo(@"No change detacted, skip uploading");
        self.isUploading = NO;
        [self runAllManagedObjectSavingCompletionBlocksWithError:nil];
        return;
    }
    for (NSString *key in self.changedRecords.allKeys) {
        if (![[workingObjects valueForKey:kParseObjectID] containsObject:key]) {
            DDLogError(@"Change for MO %@ not expected: %@", key, self.changedRecords[key]);
            self.changedRecords = [self.changedRecords setValue:nil forImmutableKeyPath:@[key]];
        }
    }
    
    //logging
    NSMutableDictionary *info = [NSMutableDictionary new];
    for (PFObject *PO in self.deleteQueue) info[PO.objectId] = PO.parseClassName;
    DDLogInfo(@"============ Start updating to server =============== \n Inserts:%@, \n Updates:%@ \n and Deletes:%@ ", [insertedManagedObjects valueForKeyPath:@"entity.name"], self.updatingClassAndValues, info);
    
    //save callbacks
    //NSMutableDictionary *callbacks = _uploadCompletionCallbacks;
    //self.uploadCompletionCallbacks = [NSMutableDictionary new];
    
    //start background update
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (EWServerObject *MO in workingObjects) {
            EWServerObject *localMO = [MO MR_inContext:localContext];
            if (!localMO) {
                DDLogVerbose(@"*** MO %@(%@) to upload haven't saved", MO.entity.name, MO.serverID);
                continue;
            }
			
			//=================>> Upload method <<===================
            NSError *error;
            BOOL success = [self updateParseObjectFromManagedObject:localMO withError:&error];
            //=======================================================
            
            if (!success) {
                DDLogError(@"---> Failed to update MO: %@", error.localizedDescription);
            }
            else if (localMO.serverID) {
                NSString *changes = [(NSSet *)self.changedRecords[localMO.serverID] allObjects].string;
                self.changedRecords = [self.changedRecords setValue:nil forImmutableKeyPath:@[localMO.serverID]];
                
                DDLogVerbose(@"===> MO %@(%@) uploaded to server with changes applied: %@. %lu to go.", localMO.entity.name, localMO.serverID, changes, (unsigned long)self.changedRecords.allKeys.count);
            }else {
                DDLogVerbose(@"+++> MO %@(%@) created on server, %lu to go.", localMO.entity.name, localMO.serverID, (unsigned long)self.changedRecords.allKeys.count);
            }
            
            //remove from queue
            [self removeObjectFromWorkingQueue:localMO];
        }
        
        for (PFObject *po in deletedServerObjects) {
            [self deleteParseObject:po];
        }
        
    } completion:^(BOOL success, NSError *error) {
        DDLogVerbose(@"=========== Finished uploading to saver ===============");
        self.isUploading = NO;
        //perform upload completion blocks (if PO finished saving first and skipped performing the blocks)
        [self runAllManagedObjectSavingCompletionBlocksWithError:error];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kEWSyncUploaded object:error];
    }];
}

- (void)resumeUploadToServer{
    NSMutableSet *workingMOs = self.workingQueue.mutableCopy;
    [workingMOs unionSet:self.updateQueue];
    [workingMOs unionSet:self.insertQueue];
    NSSet *deletePOs = [self deleteQueue];
    if (workingMOs.count > 0 || deletePOs.count > 0) {
        DDLogInfo(@"There are %lu MOs need to upload or %lu MOs need to delete, resume uploading!", (unsigned long)workingMOs.count, (unsigned long)deletePOs.count);
        [self uploadToServer];
    }
}

#pragma mark - Uploading finish callback
+ (void)addUploadingCompletionBlocks:(EWManagedObjectSaveCallbackBlock)block forServerObject:(EWServerObject *)SO{
    EWAssertMainThread
    NSMutableArray *moUploadCallbacks = [EWSync sharedInstance].uploadCompletionCallbacks[SO.objectID] ?: [NSMutableArray array];
    [moUploadCallbacks addObject:block];
    [[EWSync sharedInstance].uploadCompletionCallbacks setObject:moUploadCallbacks forKey:SO.objectID];
    [EWSync saveImmediately];
}

- (void)runAllManagedObjectSavingCompletionBlocksWithError:(NSError *)error{
    EWAssertMainThread
    [self.uploadCompletionCallbacks enumerateKeysAndObjectsUsingBlock:^(NSManagedObjectID *key, NSArray *blocks, BOOL *stop) {
        //check if MO is still updating, skip if so
        NSArray *saveCallbacks = [self.parseSaveCallbacks objectForKey:key];
        if (!saveCallbacks || saveCallbacks.count == 0) {
            //MO is not updating
            EWServerObject *MO = (EWServerObject *)[mainContext objectWithID:key];
            DDLogVerbose(@"Found MO %@(%@) has completion block when uploading finishes", MO.entity.name, MO.serverID);
            [self runManagedObjectCompletionBlockForObjectID:key withError:error];
        }
    }];
}

- (void)runManagedObjectCompletionBlockForObjectID:(NSManagedObjectID *)ID withError:(NSError *)error{
    EWAssertMainThread
    NSArray *blocks = self.uploadCompletionCallbacks[ID];
    for (EWManagedObjectSaveCallbackBlock block in blocks) {
        EWServerObject *MO = (EWServerObject *)[mainContext objectWithID:ID];
        DDLogInfo(@"===> Run MO upload completion block %@(%@)", MO.entity.name, MO.serverID);
        NSString *serverID;
        @try {
            serverID = MO.serverID;
            if (!serverID) {
                error = [[NSError alloc] initWithDomain:kWokeDomain code:kEWInvalidObjectErrorCode userInfo:@{NSLocalizedDescriptionKey: @"The ManagedObject does not have server ID when save finishes."}];
            }else{
                [self.uploadCompletionCallbacks removeObjectForKey:ID];
            }
        }
        @catch (NSException *exception) {
            error = [[NSError alloc] initWithDomain:kWokeDomain code:kEWInvalidObjectErrorCode userInfo:@{NSLocalizedDescriptionKey: @"The ManagedObject does not exists.", NSUnderlyingErrorKey: exception}];
        }
        block(MO, error);
    }
}

#pragma mark - Save observing
//observe main context
- (void)preSaveAction:(NSNotification *)notification{
    EWAssertMainThread
    
    NSManagedObjectContext *localContext = (NSManagedObjectContext *)[notification object];
    
    [self enqueueChangesInContext:localContext];
}

- (void)enqueueChangesInContext:(NSManagedObjectContext *)context{
    //BOOL hasChange = NO;
    NSSet *updatedObjects = context.updatedObjects;
    NSSet *insertedObjects = context.insertedObjects;
    NSSet *deletedObjects = context.deletedObjects;
	NSMutableSet *objects = updatedObjects.mutableCopy;
	[objects unionSet:insertedObjects];
	[objects minusSet:deletedObjects];
    
    //for updated mo
    for (EWServerObject *SO in objects) {
        //check if it's our guy
        if (![SO isKindOfClass:[EWServerObject class]]) {
            DDLogWarn(@"Found non EWServerObject saving! %@", SO.entity.name);
            continue;
        }
        //First test MO exist
        if (![context existingObjectWithID:SO.objectID error:NULL]) {
            DDLogError(@"*** MO you are trying to modify doesn't exist in the sqlite: %@", SO.objectID);
            continue;
        }
		
		//Pre-save validate
		if (![EWSync validateSO:SO]) {
			continue;
		}
		
        //check ACL
        //TODO: chenge the check access to server object level
        if (![EWSync checkAccess:SO]) {
            DDLogWarn(@"!!! Skip uploading object with no access rights %@ with changes %@", SO.serverID, SO.changedKeys.string);
            continue;
        }
        
        if ([insertedObjects containsObject:SO] || !SO.objectId) {
            //enqueue to insertQueue
            [self appendInsertQueue:SO];
            
            //*** we should not add updatedAt here, as it is the criteria for enqueue. Two Inserts could be possible: downloaded from server or created here. Therefore we need to add createdAt at local creation point.
            //change updatedAt
            //[MO setValue:[NSDate date] forKeyPath:kUpdatedDateKey];
            continue;
        }
        
        //additional check for updated object
        if ([updatedObjects containsObject:SO]) {
            NSParameterAssert(SO.objectId);
            //check if updated keys exist
            NSMutableArray *changedKeys = SO.changedKeys.mutableCopy;
            if (changedKeys) {
                //add changed keys to record
                NSMutableSet *changed = [NSMutableSet setWithArray:self.changedRecords[SO.serverID]] ?: [NSMutableSet new];
                [changed addObjectsFromArray:changedKeys];
				self.changedRecords = [self.changedRecords setValue:changed.allObjects forImmutableKeyPath:@[SO.serverID]];
                //add to queue
                [self appendUpdateQueue:SO];
                //change updatedAt
                SO.syncInfo[kRelationUpdatedTime] = [NSDate date];
            }
        }
    }
    
    for (EWServerObject *SO in deletedObjects) {
        //check if it's our guy
        if (![SO isKindOfClass:[EWServerObject class]]) continue;
        
        if (SO.serverID) {
            DDLogInfo(@"~~~> MO %@(%@) is going to be DELETED, enqueue PO to delete queue.", SO.entity.name, [SO valueForKey:kParseObjectID]);
            //get PO reference
            PFObject *PO = [PFObject objectWithoutDataWithClassName:[[SO class] serverClassName] objectId:SO.serverID];
            //remove PO from PIN
			//Not needed
            //add PO to delete queue
            [self appendObjectToDeleteQueue:PO];
        }
    }
}



#pragma mark - Upload worker
- (BOOL)updateParseObjectFromManagedObject:(EWServerObject *)serverObject withError:(NSError *__autoreleasing *)error{
	if (!error) {
		NSError __autoreleasing *err;
		error = &err;
	}
    //validation
    if (![serverObject validate]) {
        DDLogWarn(@"!!! Validation failed for %@(%@), skip upload.", serverObject.entity.name, serverObject.serverID);
        *error = [EWErrorManager invalidObjectError:serverObject];
        return NO;
    }
    //skip if updating other PFUser
    if ([serverObject.entity.name isEqualToString:kSyncUserClass] && ![(EWPerson *)serverObject isMe]) {
        DDLogError(@"Uploading user class, check your code!");
        *error = [EWErrorManager invalidObjectError:serverObject];
        return NO;
    }
    
    NSString *parseObjectId = serverObject.serverID;
    PFObject *PO;
    if (parseObjectId) {
        //download
        PO =[self getParseObjectWithClass:[[serverObject class] serverClassName] ID:parseObjectId error:error];
        if ([PO isNewerThanMO]) {
            DDLogWarn(@"The PO %@(%@) being updated from MO is newer", PO.parseClassName, PO.objectId);
        }
        if (!PO) {
            if ([*error code] == kPFErrorObjectNotFound) {
                DDLogError(@"PO %@ couldn't be found!", [[serverObject class] serverClassName]);
                serverObject.objectId = nil;
            }
			else if ([*error code] == kPFErrorConnectionFailed) {
                DDLogError(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                [serverObject uploadEventually];
                return NO;
            }
			else if (*error) {
                DDLogError(@"*** Error in getting related parse object from MO %@(%@): %@", serverObject.entity.name, serverObject.serverID, [*error localizedDescription]);
                [serverObject uploadEventually];
                return NO;
            }
            
            *error = nil;//clean error for later use
        }
    }
    
    if (!PO) {
        //insert
        PO = [PFObject objectWithClassName:[[serverObject class] serverClassName]];
        [PO pin:error];
        //TODO: need to test if we can skip saving first. For example, if there is unsaved object related, the save process will throw exception
        @try {
            //need to save before working on PFRelation
            [PO save:error];
        }
        @catch (NSException *exception) {
            DDLogError(@"Failed to save PO %@", PO);
            [PO saveEventually];
            [serverObject uploadEventually];
        }
		
        if (!*error) {
            DDLogVerbose(@"+++> CREATED PO %@(%@)", PO.parseClassName, PO.objectId);
            [serverObject setValue:PO.objectId forKey:kParseObjectID];
        }
		else{
			DDLogError(@"Failed to save new PO %@: %@", PO.parseClassName, *error);
            [serverObject uploadEventually];
            return NO;
        }
    }
    
    //==========set Parse value/relation and callback block===========
    BOOL success = [PO updateFromManagedObject:serverObject withError:error];
    //================================================================
    if (!success) {
        DDLogError(@"Failed to update PO from MO %@(%@): %@", serverObject.entity.name, serverObject.serverID, [*error localizedDescription]);
    }
    NSManagedObjectID *ID = serverObject.objectID;
    [PO saveInBackgroundWithBlock:^(BOOL succeeded, NSError *err) {
        if (success) {
            //assign connection between MO and PO
            [self performSaveCallbacksWithParseObject:PO andManagedObjectID:ID];
        }
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSError *error1;
            EWServerObject *MO_root = (EWServerObject *)[localContext existingObjectWithID:ID error:&error1];
            if (succeeded) {
                if (MO_root) {
                    //set updated time
                    MO_root.updatedAt = PO.updatedAt;
                    MO_root.syncInfo[kRelationUpdatedTime] = PO.updatedAt;
                    MO_root.syncInfo[kAttributeUpdatedTime] = PO.updatedAt;
                }
                else {
                    DDLogError(@"Failed to get %@(%@) on main thread: %@", serverObject.entity.name, serverObject.serverID, error1.localizedDescription);
                    [MO_root uploadEventually];
                }
            }else{
                if (error1.code == kPFErrorObjectNotFound){
                    DDLogError(@"*** PO not found for %@(%@), set to nil.", MO_root.entity.name, MO_root.serverID);
                    //need to check if the object is available
                    MO_root.objectId = nil;
                }
                else{
                    DDLogError(@"*** Failed to save server object: %@", error1.description);
                }
                [MO_root uploadEventually];
            }
        }];
		
    }];
    
    //Time stamp for updated date. This is very important, otherwise MO will be outdated
	//Also if do not set kUpdateDateKey, means the relation haven't been downloaded yet.
    NSAssert(serverObject.serverID, @"MO uploaded has no ID: %@", serverObject);
    return success;
}

- (void)deleteParseObject:(PFObject *)parseObject{
	@try {
		[parseObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				//Good
				DDLogVerbose(@"~~~> PO %@(%@) deleted from server", parseObject.parseClassName, parseObject.objectId);
			}
			else if (error.code == kPFErrorObjectNotFound){
				//fine
				DDLogWarn(@"~~~> Trying to deleted PO %@(%@) but not found", parseObject.parseClassName, parseObject.objectId);
			}
			else{
				//not good
                DDLogError(@"delete object failed, not sure why, %@(%@): error:%@", parseObject.parseClassName, parseObject.objectId, error);
                [parseObject deleteEventually];
			}
            
			[self removeObjectFromDeleteQueue:parseObject];
		}];
	}
	@catch (NSException *exception) {
		DDLogError(@"Error in deleting PO: %@, reason: %@", parseObject, exception.description);
		[self removeObjectFromDeleteQueue:parseObject];
		[parseObject deleteEventually];
		//[self.serverObjectCache removeObjectForKey:parseObject.objectId];
	}
}


+ (void)addParseSaveCallback:(PFObjectResultBlock)callback forManagedObjectID:(NSManagedObjectID *)objectID{
    //get global save callback
    NSMutableDictionary *saveCallbacks = [EWSync sharedInstance].parseSaveCallbacks;
    NSMutableArray *callbacks = [saveCallbacks objectForKey:objectID]?:[NSMutableArray array];
    [callbacks addObject:callback];
    //save
    [saveCallbacks setObject:callbacks forKey:objectID];
}


- (void)performSaveCallbacksWithParseObject:(PFObject *)parseObject andManagedObjectID:(NSManagedObjectID *)managedObjectID{
    //parse save completion block
    NSArray *saveCallbacks = [self.parseSaveCallbacks objectForKey:managedObjectID];
    if (saveCallbacks) {
        for (PFObjectResultBlock callback in saveCallbacks) {
            NSError *err;
            callback(parseObject, err);
        }
        [self.parseSaveCallbacks removeObjectForKey:managedObjectID];
    }
    //MO save completion block
    if (!self.isUploading) {
        [self runManagedObjectCompletionBlockForObjectID:managedObjectID withError:nil];
    }
    
}


#pragma mark - Server Updating Queue methods
//update queue
- (NSSet *)updateQueue{
    return [self getObjectFromQueue:kParseQueueUpdate];
}

- (void)appendUpdateQueue:(EWServerObject *)mo{
    //queue
    [self appendObject:mo toQueue:kParseQueueUpdate];
}

- (void)removeObjectFromUpdateQueue:(EWServerObject *)mo{
    [self removeObject:mo fromQueue:kParseQueueUpdate];
}

//insert queue
- (NSSet *)insertQueue{
    return [self getObjectFromQueue:kParseQueueInsert];
}

- (void)appendInsertQueue:(EWServerObject *)mo{
    [self appendObject:mo toQueue:kParseQueueInsert];
}

- (void)removeObjectFromInsertQueue:(EWServerObject *)mo{
    [self removeObject:mo fromQueue:kParseQueueInsert];
}

//uploading queue
- (NSSet *)workingQueue{
    return [self getObjectFromQueue:kParseQueueWorking];
}

- (void)appendObjectToWorkingQueue:(EWServerObject *)mo{
    [self appendObject:mo toQueue:kParseQueueWorking];
}

- (void)removeObjectFromWorkingQueue:(EWServerObject *)mo{
    [self removeObject:mo fromQueue:kParseQueueWorking];
}

//queue functions
- (NSSet *)getObjectFromQueue:(NSString *)queue{
    EWAssertMainThread
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:queue];
    NSMutableArray *validMOs = [array mutableCopy];
    NSMutableSet *set = [NSMutableSet new];
    for (NSString *url in array) {
		NSURL *URI = [NSURL URLWithString:url];
        NSManagedObjectID *ID = [self.context.persistentStoreCoordinator managedObjectIDForURIRepresentation:URI];
        if (!ID) {
            DDLogError(@"@@@ ManagedObjectID not found: %@", url);
            //remove from queue
            [validMOs removeObject:url];
            [[NSUserDefaults standardUserDefaults] setObject:[validMOs copy] forKey:queue];
            continue;
        }
        NSError *error;
        EWServerObject *MO = (EWServerObject *)[self.context existingObjectWithID:ID error:&error];
        if (MO) {
            [set addObject:MO];
        }else{
            DDLogError(@"*** Serious error: trying to fetch MO from main context failed. ObjectID:%@ \nError:%@", ID, error.description);
            //remove from the queue
			[validMOs removeObject:url];
			[[NSUserDefaults standardUserDefaults] setObject:[validMOs copy] forKey:queue];
        }
    }
    return [set copy];
}

- (void)appendObject:(EWServerObject *)mo toQueue:(NSString *)queue{
    
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:queue];
    NSMutableSet *set = [[NSMutableSet setWithArray:array] mutableCopy]?:[NSMutableSet new];
    NSManagedObjectID *objectID = mo.objectID;
    if ([objectID isTemporaryID]) {
        [mo.managedObjectContext obtainPermanentIDsForObjects:@[mo] error:NULL];
        objectID = mo.objectID;
    }
    NSString *URI = objectID.URIRepresentation.absoluteString;
    if (![set containsObject:URI]) {
        [set addObject:URI];
        [[NSUserDefaults standardUserDefaults] setObject:set.allObjects forKey:queue];
        if ([queue isEqualToString:kParseQueueInsert]) {
            DDLogDebug(@"+++> MO %@(%@) added to INSERT queue", mo.entity.name, mo.objectID);
        }else if([queue isEqualToString:kParseQueueUpdate]){
            DDLogDebug(@"===> MO %@(%@) added to UPDATED queue with changes: %@", mo.entity.name, mo.serverID, mo.changedKeys.string);
        }
    }
}

- (void)removeObject:(EWServerObject *)mo fromQueue:(NSString *)queue{
    NSMutableArray *array = [[[NSUserDefaults standardUserDefaults] valueForKey:queue] mutableCopy];
    NSManagedObjectID *objectID = mo.objectID;
    NSString *str = objectID.URIRepresentation.absoluteString;
    if ([array containsObject:str]) {
        [array removeObject:str];
        [[NSUserDefaults standardUserDefaults] setValue:[array copy] forKey:queue];
    }
}

- (void)clearQueue:(NSString *)queue{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:queue];
}

- (BOOL)contains:(EWServerObject *)mo inQueue:(NSString *)queue{
    NSMutableArray *array = [[[NSUserDefaults standardUserDefaults] valueForKey:queue] mutableCopy];
    NSString *str = mo.objectID.URIRepresentation.absoluteString;
    BOOL contain = [array containsObject:str];
    return contain;
}

//DeletedQueue underlying is a dictionary of objectId:className
- (NSSet *)deleteQueue{
    NSDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy];
    NSParameterAssert(!dic || [dic isKindOfClass:[NSDictionary class]]);
    NSMutableSet *set = [NSMutableSet new];
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *ID, NSString *className, BOOL *stop) {
        [set addObject:[PFObject objectWithoutDataWithClassName:className objectId:ID]];
    }];
    return [set copy];
}

- (void)appendObjectToDeleteQueue:(PFObject *)object{
    if (!object) return;
    NSMutableDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy]?:[NSMutableDictionary new];;
    [dic setObject:object.parseClassName forKey:object.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[dic copy] forKey:kParseQueueDelete];
}

- (void)removeObjectFromDeleteQueue:(PFObject *)object{
    if (!object) return;
    NSMutableDictionary *dic = [[[NSUserDefaults standardUserDefaults] valueForKey:kParseQueueDelete] mutableCopy];
    [dic removeObjectForKey:object.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[dic copy] forKey:kParseQueueDelete];
}

//changed records
- (NSDictionary *)changedRecords{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kChangedRecords] mutableCopy] ?: [NSMutableDictionary new];
}

- (void)setChangedRecords:(NSDictionary *)changedRecords{
    [[NSUserDefaults standardUserDefaults] setValue:changedRecords forKey:kChangedRecords];
}

#pragma mark - Core Data
+ (NSManagedObject *)findObjectWithClass:(NSString *)className withServerID:(NSString *)serverID error:(NSError *__autoreleasing *)error{
	EWAssertMainThread
    NSManagedObject * MO = [self findObjectWithClass:className withServerID:serverID inContext:mainContext error:error];
    return MO;
}

+ (NSManagedObject *)findObjectWithClass:(NSString *)className withServerID:(NSString *)serverID inContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error{
    NSParameterAssert(className);
    if (serverID == nil) {
        DDLogError(@"%s !!! Passed in nil to get current MO", __func__);
        return nil;
	}
	if (!error) {
		NSError __autoreleasing *err;
		error = &err;
	}
    EWServerObject * MO = [NSClassFromString(className) MR_findFirstByAttribute:kParseObjectID withValue:serverID inContext:context];
    if (!MO) {
        PFObject *PO = [[EWSync sharedInstance] getParseObjectWithClass:className ID:serverID error:error];
        MO = [PO managedObjectInContext:context];
        if (!MO) {
            DDLogError(@"Failed getting MO with class (%@): %@", className, (*error).description);
        }
    }
    return MO;
}

#pragma mark -
+ (NSArray *)findManagedObjectFromServerWithQuery:(PFQuery *)query saveInContext:(NSManagedObjectContext *)context error:(NSError **)error{
    NSArray *result = [query findObjects:error];
    [PFObject pinAll:result error:error];
    NSMutableArray *resultMOs = [NSMutableArray array];
    for (PFObject *PO in result) {
        //[[EWSync sharedInstance] setCachedParseObject:PO];
        EWServerObject *MO;
        MO = [PO managedObjectInContext:context];
        if ([MO validate]) {
            [resultMOs addObject:MO];
        } else {
            DDLogError(@"***The MO downloaded from query %@(%@) is not valide", MO.entity.name, MO.serverID);
            [MO remove];
        }
    }
    return resultMOs;
}

+ (void)findManagedObjectsFromServerInBackgroundWithQuery:(PFQuery *)query completion:(PFArrayResultBlock)block{//cache query
    EWAssertMainThread
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!objects && error) {
            DDLogError(@"Failed to get PO: %@", error);
            if (block) {
                block(nil, error);
            }
            return;
        }
        //convert to MO
        [PFObject pinAll:objects error:&error];
        __block NSMutableArray *localMOs = [NSMutableArray array];
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            for (PFObject *PO in objects) {
                EWServerObject *MO;
                if ([PO.localClassName isEqualToString:kSyncUserClass] && PO.objectId != [PFUser currentUser].objectId) {
                    MO = [PO managedObjectInContext:localContext];
                }
                else {
                    MO = [PO managedObjectInContext:localContext option:EWSyncOptionUpdateRelation completion:NULL];
                }
                if ([MO validate]) {
                    [localMOs addObject:MO];
                } else {
                    DDLogError(@"The MO downloaded from query %@(%@) is not valide => delete", MO.entity.name, MO.serverID);
                    [MO remove];
                }
            }
        } completion:^(BOOL contextDidSave, NSError *error) {
            if (block) {
                NSMutableArray *results = [NSMutableArray array];
                for (EWServerObject *MO in localMOs) {
                    [results addObject:[MO MR_inContext:mainContext]];
                }
                block(results, error);
            }
        }];
    }];
}

#pragma mark -
+ (BOOL)validateSO:(EWServerObject *)SO{
    //validate MO, only used when uploading MO to PO
    BOOL good = [EWSync validateSO:SO andTryToFix:NO];
    
    return good;
}

+ (BOOL)validateSO:(EWServerObject *)SO andTryToFix:(BOOL)tryFix{
    if (!SO) {
        return NO;
    }
    //validate MO, only used when uploading MO to PO
    BOOL good = YES;
    
    if (!SO.updated && SO.serverID) {
        DDLogWarn(@"The %@(%@) you are trying to validate haven't been downloaded fully. Skip validating.", SO.entity.name, SO.serverID);
        return NO;
    }
	
	good = [SO validate];
	if (!good) {
		if (!tryFix) {
			return NO;
		}
		[SO refresh:nil];
		good = [SO validate];
	}
	
    if (!good) {
        DDLogError(@"*** %@(%@) failed in validation after trying to fix", SO.entity.name, SO.serverID);
    }
    
    return good;
    
}


+ (BOOL)checkAccess:(EWServerObject *)SO{
    if (!SO.serverID) {
        return YES;
    }
    
    //first see if cached PO exist
    PFObject *po = [[EWSync sharedInstance] getCachedParseObjectWithClass:[[SO class] serverClassName] ID:SO.serverID];
    if (po.ACL == nil) [po fetchIfNeededAndSaveToCache:nil];
    if (po.ACL != nil) {
        BOOL write = [po.ACL getPublicWriteAccess] || [po.ACL getWriteAccessForUser:[PFUser currentUser]];
        return write;
    }
    
    //if no ACL, use MO to determine
    if (![po isKindOfClass:[PFUser class]]) DDLogWarn(@"PO %@(%@) has NO ACL!", po.parseClassName, po.objectId);
    EWPerson *p = (EWPerson *)SO.ownerObject;
    if (p.isMe){
        return YES;
    }
    return NO;
}


#pragma mark - Parse helper methods

//cache
- (PFObject *)getCachedParseObjectWithClass:(NSString *)className ID:(NSString *)objectId{
    //When an object is pinned, every time you update it by fetching or saving new data, the copy in the local datastore will be updated automatically. You don't need to worry about it at all.
    NSError *err;
    PFObject *object = [PFObject objectWithoutDataWithClassName:className objectId:objectId];
    if (!object.isDataAvailable) {
        [object fetchFromLocalDatastore:&err];
    }
//    PFQuery *query = [PFQuery queryWithClassName:className];
//    [query fromLocalDatastore];
//    PFObject *PO = [query getObjectWithId:className error:&err];
    if (!object && err) {
        DDLogError(@"Failed to get cached PO %@(%@):%@", className, objectId, err.localizedDescription);
    }
    if (object.isDataAvailable) {
        return object;
    }
    return nil;
}

- (void)setCachedParseObject:(PFObject *)PO {
    if (!PO) {
        DDLogError(@"Set nil for PO cache");
        return;
    }
    if (PO.isDataAvailable) {
        NSError *err;
        DDLogVerbose(@"Pin PO %@(%@) to cache", PO.parseClassName, PO.objectId);
        TICK
        [PO pin:&err];
        TOCK
        if (err) {
            DDLogError(@"Failed to set cached PO %@(%@):%@", PO.parseClassName, PO.objectId, err.localizedDescription);
        }
        //[self.serverObjectCache setObject:PO forKey:PO.objectId];
        
		//You can store a PFObject in the local datastore by pinning it. Pinning a PFObject is recursive, just like saving, so any objects that are pointed to by the one you are pinning will also be pinned.

    }else{
        DDLogError(@"%s The PO passed in doesn't have data, please check!(%@)",__FUNCTION__, PO);
    }
}

//TODO: move to PFObject+EWSync
- (PFObject *)getParseObjectWithClass:(NSString *)class ID:(NSString *)ID error:(NSError **)error{
    if (!ID) {
        DDLogError(@"%s Passed in empty ID, upload first!", __func__);
        return nil;
    }
    
    //try to find PO in the pool first
    PFObject *object = [self getCachedParseObjectWithClass:class ID:ID];
	if (!object) {
		object = [PFObject objectWithoutDataWithClassName:class objectId:ID];
	}
    //if not found, then download
    if (!object.isDataAvailable) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:object.localClassName inManagedObjectContext:mainContext];
        //fetch from server if not found
        //or if PO doesn't have data avaiable
        //or if PO is older than MO
        PFQuery *q = [PFQuery queryWithClassName:class];
        [q whereKey:kParseObjectID equalTo:ID];
        //add other uni-direction relationship as well (to masximize data per call)
        [entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *obj, BOOL *stop) {
            if (obj.isToMany && !obj.inverseRelationship) {
                [q includeKey:key];
            }
        }];
        
        //find on server
		object = [q findObjects:error].firstObject;
		[self setCachedParseObject:object];
    }
    return object;
}


#pragma mark - Tools
- (NSString *)description{
    //print current states and queues
    NSMutableString *string = [NSMutableString stringWithFormat:@"EWSync object with current reachability: %d", [EWSync isReachable]];
    [string appendFormat:@"\nCurrent updating item: %@", self.updatingClassAndValues];
    [string appendFormat:@"\nCurrent inserting item: %@", [self.insertQueue valueForKey:kParseObjectID]];
    [string appendFormat:@"\nCurrent deleting item: %@", [self.deleteQueue valueForKey:kParseObjectID]];
    return string;
}


- (NSDictionary *)updatingClassAndValues{
    NSMutableDictionary *info = self.changedRecords.mutableCopy;
    [self.changedRecords enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *changedKeys, BOOL *stop) {
        PFObject *PO;// = [self getCachedParseObjectWithClass:?? ID:key];
        if (PO) {
            [info removeObjectForKey:key];
            info[[NSString stringWithFormat:@"%@(%@)", PO.parseClassName, key]] = changedKeys.string;
        } else {
            info[key] = changedKeys.string;
        }
    }];
    return info.copy;
}

@end

