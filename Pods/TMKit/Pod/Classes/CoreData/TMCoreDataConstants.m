//
//  TMCoreDataConstants.m
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

#import "TMCoreDataConstants.h"

NSString * const TMSyncChangeTypeNames[] = {
    @"Unknown",
    @"Inserted",
    @"Deleted",
    @"Attribute Changed",
    @"Relationship Changed",
};

NSString * const TMSyncIDAttributeName = @"tmSyncID";

NSString * const TMSyncChangeDataModelName = @"TMSyncChange";
NSString * const TMSyncChangeSetDataModelName = @"TMSyncChangeSet";