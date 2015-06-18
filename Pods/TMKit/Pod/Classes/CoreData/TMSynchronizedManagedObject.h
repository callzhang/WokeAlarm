//
//  TICDSSynchronizedManagedObject.h
//  Pods
//
//  Created by Zitao Xiong on 6/13/15.
//
//

#import <CoreData/CoreData.h>

@interface TMSynchronizedManagedObject : NSManagedObject
// If there are keys that you wish to exclude from synchronization they can be detailed in this set.
+ (NSSet *)keysForWhichSyncChangesWillNotBeCreated;

//@property (weak, nonatomic, readonly) NSManagedObjectContext *syncChangesMOC;
@property (nonatomic, copy) NSString *tmSyncID;

- (void)createSyncChangeToSyncManagedContext:(NSManagedObjectContext *)syncManagedContext;
@end
