//
//  TMCoreDataSyncManager.m
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

#import "TMCoreDataSyncManager.h"
#import "NSManagedObjectContext+TMKitAddition.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "TMCoreDataFactory.h"
#import "TMSynchronizedManagedObject.h"
#import "TMCoreDataConstants.h"

@interface TMCoreDataSyncManager()<TMCoreDataFactoryDelegate>
@property (nonatomic, strong) TMCoreDataFactory *coreDataFactory;
@end

@implementation TMCoreDataSyncManager
- (instancetype)init {
    self = [super init];
    if (self) {
        _syncChangesMOCs = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
    return self;
}

/**
 *  Pending remove synchronzied and documentSyncManager
 *
 */
- (void)registerPrimaryDocumentManagedObjectContext:(NSManagedObjectContext *)primaryManagedObjectContext {
    self.primaryDocumentMOC = primaryManagedObjectContext;
    self.primaryDocumentMOC.documentSyncManager = self;
    NSManagedObjectContext *synchronizedManagedObjectContext = [self addSyncChangesMocForDocumentMoc:self.primaryDocumentMOC];
    synchronizedManagedObjectContext.synchronized = YES;
    synchronizedManagedObjectContext.documentSyncManager = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchronizedMOCWillSave:) name:NSManagedObjectContextWillSaveNotification object:self.primaryDocumentMOC];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchronizedMOCDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.primaryDocumentMOC];
}

#pragma mark - MANAGED OBJECT CONTEXT DID SAVE BEHAVIOR

- (void)synchronizedMOCWillSave:(NSNotification *)notification {
    NSManagedObjectContext *documentManagedObjectContext = notification.object;
    if (documentManagedObjectContext != self.primaryDocumentMOC) {
        NSLog(@"%s Processing a synchronizedMOCWillSave: method for a MOC that isn't the primary document MOC", __PRETTY_FUNCTION__);
        return;
    }
    
    //    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didBeginProcessingSyncChangesBeforeManagedObjectContextWillSave:)]) {
    //        [self runOnMainQueueWithoutDeadlocking:^{
    //            [(id)self.delegate documentSyncManager:self didBeginProcessingSyncChangesBeforeManagedObjectContextWillSave:documentManagedObjectContext];
    //        }];
    //    }

    NSManagedObjectContext *synchronizedContext = [self syncChangesMocForDocumentMoc:documentManagedObjectContext];
    
    NSSet *insertedObjects = [documentManagedObjectContext insertedObjects];
        for (TMSynchronizedManagedObject *insertedObject in insertedObjects) {
            [insertedObject createSyncChangeToSyncManagedContext:synchronizedContext];
        }
    
        NSSet *updatedObjects = [documentManagedObjectContext updatedObjects];
        for (TMSynchronizedManagedObject *updatedObject in updatedObjects) {
            [updatedObject createSyncChangeToSyncManagedContext:synchronizedContext];
        }
    
        NSSet *deletedObjects = [documentManagedObjectContext deletedObjects];
        for (TMSynchronizedManagedObject *deletedObject in deletedObjects) {
            [deletedObject createSyncChangeToSyncManagedContext:synchronizedContext];
        }

    NSError *anyError = nil;
    BOOL success = NO;
    
    success = [synchronizedContext save:&anyError];
    
    if (success == NO) {
        DDLogError(@"Sync Manager failed to save Sync Changes context with error: %@", anyError);
        DDLogError(@"Sync Manager cannot continue processing any further, so bailing");
        //        if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFailToProcessSyncChangesBeforeManagedObjectContextWillSave:withError:)]) {
        //            [self runOnMainQueueWithoutDeadlocking:^{
        //                [(id)self.delegate documentSyncManager:self didFailToProcessSyncChangesBeforeManagedObjectContextWillSave:documentManagedObjectContext withError:[TICDSError errorWithCode:TICDSErrorCodeFailedToSaveSyncChangesMOC underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        //            }];
        //        }
        
        return;
    }
    
    DDLogVerbose(@"Sync Manager saved Sync Changes context successfully");
    //    if ([self ti_delegateRespondsToSelector:@selector(documentSyncManager:didFinishProcessingSyncChangesBeforeManagedObjectContextWillSave:)]) {
    //        [self runOnMainQueueWithoutDeadlocking:^{
    //            [(id)self.delegate documentSyncManager:self didFinishProcessingSyncChangesBeforeManagedObjectContextWillSave:documentManagedObjectContext];
    //        }];
    //    }
}

- (void)synchronizedMOCDidSave:(NSNotification *)notification {
    NSManagedObjectContext *documentManagedObjectContext = notification.object;
    if (documentManagedObjectContext != self.primaryDocumentMOC) {
        NSLog(@"%s Processing a synchronizedMOCWillSave: method for a MOC that isn't the primary document MOC", __PRETTY_FUNCTION__);
        return;
    }
    
    //    [self processSyncTransactionsReadyToBeClosed];
    
    DDLogVerbose(@"Asking delegate if we should sync after saving");
    //    BOOL shouldSync = [self ti_delegateRespondsToSelector:@selector(documentSyncManager:shouldBeginSynchronizingAfterManagedObjectContextDidSave:)] && [(id)self.delegate documentSyncManager:self shouldBeginSynchronizingAfterManagedObjectContextDidSave:documentManagedObjectContext];
    //    if (shouldSync == NO) {
    //        TICDSLog(TICDSLogVerbosityEveryStep, @"Delegate denied synchronization after saving");
    //        return;
    //    }
    
    DDLogVerbose(@"Delegate allowed synchronization after saving");
    [self initiateSynchronization];
}

- (void)initiateSynchronization {
    //    if (self.state == TICDSDocumentSyncManagerStateSynchronizing) {
    //        TICDSLog(TICDSLogVerbosityEveryStep, @"We're already syncing, so queueing another sync.");
    //        self.queuedSyncsCount = 1;
    //        return;
    //    }
    //
    //    TICDSLog(TICDSLogVerbosityEveryStep, @"Initiation of synchronization");
    //
    //    self.state = TICDSDocumentSyncManagerStateSynchronizing;
    //
    //    [self beginBackgroundTask];
    //
    //    [self startPreSynchronizationProcess];
}

#pragma mark - ADDITIONAL MANAGED OBJECT CONTEXTS

- (void)addManagedObjectContext:(NSManagedObjectContext *)aContext
{
    DDLogVerbose(@"Adding SyncChanges MOC for document context: %@", aContext);
    [self addSyncChangesMocForDocumentMoc:aContext];
}

- (NSManagedObjectContext *)addSyncChangesMocForDocumentMoc:(NSManagedObjectContext *)documentManagedObjectContext
{
    NSManagedObjectContext *syncChangesManagedObjectContext = [self.syncChangesMOCs valueForKey:[self keyForContext:documentManagedObjectContext]];
    
    if (syncChangesManagedObjectContext != nil) {
        return syncChangesManagedObjectContext;
    }
    
    [documentManagedObjectContext setDocumentSyncManager:self];
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [self.coreDataFactory persistentStoreCoordinator];
    if (persistentStoreCoordinator == nil) {
        DDLogVerbose(@"We got a nil NSPersistentStoreCoordinator back from the Core Data Factory, trying to reset the factory.");
        self.coreDataFactory = nil;
        persistentStoreCoordinator = [self.coreDataFactory persistentStoreCoordinator];
        if (persistentStoreCoordinator == nil) {
            DDLogError(@"Resetting the Core Data Factory didn't help, bailing from this method.");
            return nil;
        }
    }
    
    syncChangesManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    syncChangesManagedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
    NSError *error = nil;
    [syncChangesManagedObjectContext save:&error];
    if (error != nil) {
        DDLogError(@"Was not able to save the freshly created MOC.");
    }
    
    [self.syncChangesMOCs setValue:syncChangesManagedObjectContext forKey:[self keyForContext:documentManagedObjectContext]];
    
    return syncChangesManagedObjectContext;
}

- (NSManagedObjectContext *)syncChangesMocForDocumentMoc:(NSManagedObjectContext *)documentManagedObjectContext {
    NSManagedObjectContext *syncChangesManagedObjectContext = [self.syncChangesMOCs valueForKey:[self keyForContext:documentManagedObjectContext]];
    
    if (syncChangesManagedObjectContext == nil) {
        DDLogError(@"SyncChanges MOC was requested for a managed object context that hasn't yet been added, so adding it before proceeding");
        
        syncChangesManagedObjectContext = [self addSyncChangesMocForDocumentMoc:documentManagedObjectContext];
        if (syncChangesManagedObjectContext == nil) {
            NSLog(@"%s There was a problem getting the sync changes MOC for the document MOC.", __PRETTY_FUNCTION__);
        }
    }
    
    return syncChangesManagedObjectContext;
}

- (NSString *)keyForContext:(NSManagedObjectContext *)aContext
{
    return [NSString stringWithFormat:@"%p", aContext];
}

#pragma mark - Lazy Accessory
- (TMCoreDataFactory *)coreDataFactory {
    if (_coreDataFactory) {
        return _coreDataFactory;
    }
    
    DDLogVerbose(@"Creating Core Data Factory (TICoreDataFactory)");
    _coreDataFactory = [[TMCoreDataFactory alloc] initWithMomdName:TMSyncChangeDataModelName];
    [_coreDataFactory setDelegate:self];
    [_coreDataFactory setPersistentStoreType:TMSyncChangesCoreDataPersistentStoreType];
//    [_coreDataFactory setPersistentStoreDataPath:self.unsynchronizedSyncChangesStorePath];
    [_coreDataFactory setPersistentStoreDataFileName:@"TICoreDataSync.sqlite"];

    return _coreDataFactory;
}

#pragma mark - TICoreDataFactory Delegate

- (void)coreDataFactory:(TMCoreDataFactory *)aFactory encounteredError:(NSError *)anError {
    DDLogError(@"TICoreDataFactory error: %@", anError);
}
@end
