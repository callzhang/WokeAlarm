//
//  TMSectionItemRowDataSource.h
//  Pods
//
//  Created by Zitao Xiong on 6/2/15.
//
//

#import <Foundation/Foundation.h>
@import CoreData;
@class TMRowItem, TMSectionItem;

@protocol TMSectionItemRowDataSourceDelegate
- (void)didInsertRowItem:(TMRowItem *)object;
- (void)didRemoveRowItem:(TMRowItem *)object;
@end

@protocol TMSectionItemRowDataSource
@required
- (NSUInteger)indexOfRowItem:(TMRowItem *)rowItem;
#pragma mark - TMRowItem Accessor
- (NSUInteger)countOfRowItems;
- (id)objectInRowItemsAtIndex:(NSUInteger)idx;
- (void)insertObject:(TMRowItem *)anObject inRowItemsAtIndex:(NSUInteger)idx;
- (void)insertRowItems:(NSArray *)RowItemsArray atIndexes:(NSIndexSet *)indexes;
- (void)removeObjectFromRowItemsAtIndex:(NSUInteger)idx;
- (void)removeRowItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRowItemsAtIndex:(NSUInteger)idx withObject:(TMRowItem *)anObject;
- (void)replaceRowItemsAtIndexes:(NSIndexSet *)indexes withRowItems:(NSArray *)lowerRowItemsArray;
- (void)addToRowItems:(TMRowItem *)anObject;
- (void)removeFromRowItems:(TMRowItem *)rowItems;

@property (nonatomic, weak) NSObject<TMSectionItemRowDataSourceDelegate> *delegate;
@property (nonatomic, weak) TMSectionItem *sectionItem;
- (id<NSFetchedResultsSectionInfo>)sectionInfo;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

- (NSArray *)filterRowItemsUsingPredicate:(NSPredicate *)predicate;
@end
