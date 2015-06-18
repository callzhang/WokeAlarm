//
//  TMCoreDataConstants.h
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

#import <Foundation/Foundation.h>
//#define TMSyncChangesCoreDataPersistentStoreType NSBinaryStoreType
#define TMSyncChangesCoreDataPersistentStoreType NSSQLiteStoreType
#define TMSyncChangeSetsCoreDataPersistentStoreType NSSQLiteStoreType


extern NSString * const TMSyncChangeTypeNames[];
extern NSString * const TMSyncIDAttributeName;

extern NSString * const TMSyncChangeDataModelName;
extern NSString * const TMSyncChangeSetDataModelName;