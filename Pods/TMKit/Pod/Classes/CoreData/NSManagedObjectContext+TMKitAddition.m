//
//  NSManagedObjectContext+TMKitAddition.m
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

#import "NSManagedObjectContext+TMKitAddition.h"

#import <objc/runtime.h>
#import "TMCoreDataSyncManager.h"

NSString const* NSManagedObjectContextTMPAdditionsDocumentSyncManagerKey = @"NSManagedObjectContextTMPAdditionsDocumentSyncManagerKey";
NSString const* NSManagedObjectContextTMPAdditionsSynchronizedKey = @"NSManagedObjectContextTMPAdditionsSynchronizedKey";

@implementation NSManagedObjectContext (TICDSAdditions)

- (void)setDocumentSyncManager:(TMCoreDataSyncManager *)documentSyncManager {
    objc_setAssociatedObject(self, &NSManagedObjectContextTMPAdditionsDocumentSyncManagerKey, documentSyncManager, OBJC_ASSOCIATION_RETAIN);
}

- (TMCoreDataSyncManager *)documentSyncManager {
    return objc_getAssociatedObject(self, &NSManagedObjectContextTMPAdditionsDocumentSyncManagerKey);
}

- (void)setSynchronized:(BOOL)synchronized {
    objc_setAssociatedObject(self, &NSManagedObjectContextTMPAdditionsSynchronizedKey, @(synchronized), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)isSynchronized {
    NSNumber *isSynchronized = objc_getAssociatedObject(self, &NSManagedObjectContextTMPAdditionsSynchronizedKey);
    return [isSynchronized boolValue];
}

@end
