//
//  TMCoreDataSyncManager.h
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

@import Foundation;
@import CoreData;

@interface TMCoreDataSyncManager : NSObject

@property (nonatomic, strong) NSManagedObjectContext *primaryDocumentMOC;

/** A dictionary containing the SyncChanges managed object contexts to use for each document managed object context. */
@property (strong) NSMutableDictionary *syncChangesMOCs;

- (void)registerPrimaryDocumentManagedObjectContext:(NSManagedObjectContext *)primaryManagedObjectContext;
@end
