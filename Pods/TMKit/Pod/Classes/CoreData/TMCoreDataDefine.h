//
//  TMCoreDataDefine.h
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

#ifndef Pods_TMCoreDataDefine_h
#define Pods_TMCoreDataDefine_h

#pragma mark Sync Changes
/** @name Sync Changes */
/** The type of a sync change
 */
typedef NS_ENUM(NSInteger, TMSyncChangeType)
{
    TMSyncChangeTypeUnknown = 0,
    TMSyncChangeTypeObjectInserted = 1,
    TMSyncChangeTypeAttributeChanged = 2,
    TMSyncChangeTypeToOneRelationshipChanged = 3,
    TMSyncChangeTypeToManyRelationshipChangedByAddingObject = 4,
    TMSyncChangeTypeToManyRelationshipChangedByRemovingObject = 5,
    TMSyncChangeTypeObjectDeleted = 10
};
#endif
