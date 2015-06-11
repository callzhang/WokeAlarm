//
//  TMSectionItemRowItemsDataSource.m
//  Pods
//
//  Created by Zitao Xiong on 6/2/15.
//
//

#import "TMSectionItemArrayRowItemDataSource.h"
#import "TMRowItem.h"

@interface TMSectionItemArrayRowItemDataSource ()
@property (nonatomic, strong) NSMutableArray *rowItems;


@end
@implementation TMSectionItemArrayRowItemDataSource
@synthesize delegate = _delegate;
@synthesize sectionItem = _sectionItem;
@synthesize fetchedResultsController = _fetchedResultsController;

- (NSMutableArray *)rowItems {
    if (!_rowItems) {
        _rowItems = [NSMutableArray array];
    }
    
    return _rowItems;
}
#pragma mark - TMRowItem Accessor
- (NSUInteger)indexOfRowItem:(TMRowItem *)rowItem {
    return [self.rowItems indexOfObject:rowItem];
}

- (void)addToRowItems:(TMRowItem *)rowItems {
    [self.rowItems addObject:rowItems];
    [self didInsertRowItem:rowItems];
}

- (void)removeFromRowItems:(TMRowItem *)rowItems {
    [self.rowItems removeObject:rowItems];
    [self didRemoveRowItem:rowItems];
}

- (NSUInteger)countOfRowItems {
    return [self.rowItems count];
}

- (TMRowItem *)objectInRowItemsAtIndex:(NSUInteger)idx {
    return [self.rowItems objectAtIndex:idx];
}

- (void)insertObject:(TMRowItem *)aRowItems inRowItemsAtIndex:(NSUInteger)idx {
    [self.rowItems insertObject:aRowItems atIndex:idx];
    [self didInsertRowItem:aRowItems];
}

- (void)insertRowItems:(NSArray *)searchToReplaceArray atIndexes:(NSIndexSet *)indexes {
    [self.rowItems insertObjects:searchToReplaceArray atIndexes:indexes];
    [searchToReplaceArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self didInsertRowItem:obj];
    }];
}

- (void)removeObjectFromRowItemsAtIndex:(NSUInteger)idx {
    TMRowItem *obj = [self.rowItems objectAtIndex:idx];
    [self.rowItems removeObjectAtIndex:idx];
    [self didRemoveRowItem:obj];
}

- (void)removeRowItemsAtIndexes:(NSIndexSet *)indexes {
    NSArray *removedObjects = [self.rowItems objectsAtIndexes:indexes];
    [self.rowItems removeObjectsAtIndexes:indexes];
    [removedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self didRemoveRowItem:obj];
    }];
}

- (void)replaceObjectInRowItemsAtIndex:(NSUInteger)idx withObject:(TMRowItem *)aRowItems {
    [self.rowItems replaceObjectAtIndex:idx withObject:aRowItems];
    [self didInsertRowItem:aRowItems];
}

- (void)replaceRowItemsAtIndexes:(NSIndexSet *)indexes withRowItems:(NSArray *)searchToReplaceArray {
    [self.rowItems replaceObjectsAtIndexes:indexes withObjects:searchToReplaceArray];
    [searchToReplaceArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self didInsertRowItem:obj];
    }];
}

- (void)didInsertRowItem:(TMRowItem *)object {
    if ([self.delegate respondsToSelector:@selector(didInsertRowItem:)]) {
        [self.delegate didInsertRowItem:object];
    }
}

- (void)didRemoveRowItem:(TMRowItem *)object {
    if ([self.delegate respondsToSelector:@selector(didRemoveRowItem:)]) {
        [self.delegate didRemoveRowItem:object];
    }
}

- (NSArray *)filterRowItemsUsingPredicate:(NSPredicate *)predicate {
    return [self.rowItems filteredArrayUsingPredicate:predicate];
}

- (id<NSFetchedResultsSectionInfo>)sectionInfo {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"You can't call %@ when section item is backed by Array", NSStringFromSelector(_cmd)] userInfo:nil];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    [NSException raise:NSInternalInconsistencyException format:@"You can't call %@ when section item is backed by Array", NSStringFromSelector(_cmd)];
}

- (NSFetchedResultsController *)fetchedResultsController {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"You can't call %@ when section item is backed by Array", NSStringFromSelector(_cmd)] userInfo:nil];
}
@end
