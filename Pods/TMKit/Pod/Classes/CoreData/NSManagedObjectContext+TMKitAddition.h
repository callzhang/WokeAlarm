//
//  NSManagedObjectContext+TMKitAddition.h
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

#import <CoreData/CoreData.h>
#import "TMCoreDataSyncManager.h"

@interface NSManagedObjectContext (TMKitAddition)
/** The document sync manager responsible for this managed object context's underlying persistent store/document.

 This property will automatically be set when registering a document sync manager with this context. */
@property (nonatomic, weak) TMCoreDataSyncManager *documentSyncManager;

/**
 In order for the changes that take place in a managed object context to be recorded as sync changes the managed object context must be marked as synchronized.
 */
@property (nonatomic, assign, getter = isSynchronized) BOOL synchronized;
@end
