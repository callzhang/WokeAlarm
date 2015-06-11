//
//  TMSectionItemFetchedResultsRowDataSource.m
//  Pods
//
//  Created by Zitao Xiong on 6/2/15.
//
//

#import "TMSectionItemFetchedResultsRowItemDataSource.h"
#import "TMRowItem.h"
#import "TMTableViewFetchedResultConfiguration.h"
#import "TMSectionItem.h"
#import "TMRowItem+Protected.h"
#import "TMTableViewBuilder.h"
@import CoreData;

@interface TMSectionItemFetchedResultsRowItemDataSource()
@property (nonatomic, strong) NSCache *rowItemsCache;
@end

@implementation TMSectionItemFetchedResultsRowItemDataSource
@synthesize sectionItem = _sectionItem;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize delegate = _delegate;

- (NSCache *)rowItemsCache {
    if (!_rowItemsCache) {
        _rowItemsCache = [[NSCache alloc] init];
    }
    
    return _rowItemsCache;
}

- (NSUInteger)countOfRowItems {
    return [self.sectionInfo numberOfObjects];
}

- (TMRowItem *)createdRowItemForManagedObject:(NSManagedObject *)managedObject {
    //TODO: thinking about using entity description instead of class name
    TMRowItem *rowItem;
    
    TMTableViewFetchedResultConfiguration *configuration = [self.sectionItem.tableViewBuilder configurationForManagedObjectIdentifier:NSStringFromClass([managedObject class])];
    
    rowItem = [configuration createdRowItemForMangedObject:managedObject];
    if ([self.delegate respondsToSelector:@selector(didInsertRowItem:)]) {
        [self.delegate didInsertRowItem:rowItem];
    }
    return rowItem;
}

- (id)objectInRowItemsAtIndex:(NSUInteger)idx {
    NSIndexPath *indexPath = nil;
    if (self.sectionItem.tableViewBuilder.managedType == TMTableViewBuilderManagedTypeArray) {
        indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
    }
    else if (self.sectionItem.tableViewBuilder.managedType == TMTableViewBuilderManagedTypeFetchedResultsController) {
        indexPath = [NSIndexPath indexPathForRow:idx inSection:self.sectionItem.section];
    }
    else {
        NSAssert(NO, @"not handle managed type for tableviewBuilder");
    }
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    TMRowItem *rowItem = [self.rowItemsCache objectForKey:managedObject.objectID];
    if (!rowItem) {
        rowItem = [self createdRowItemForManagedObject:managedObject];
        [self.rowItemsCache setObject:rowItem forKey:managedObject.objectID];
    }
    
    return rowItem;
}

- (NSUInteger)indexOfRowItem:(TMRowItem *)rowItem {
    NSManagedObject *mangedObject = rowItem.managedObject;
    return [self.fetchedResultsController indexPathForObject:mangedObject].row;
}

- (CGFloat)estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (id<NSFetchedResultsSectionInfo>)sectionInfo {
    if (self.sectionItem.tableViewBuilder.managedType == TMTableViewBuilderManagedTypeFetchedResultsController) {
        id<NSFetchedResultsSectionInfo> section = [self.fetchedResultsController.sections objectAtIndex:self.sectionItem.section];
        return section;
    }
    else if (self.sectionItem.tableViewBuilder.managedType == TMTableViewBuilderManagedTypeArray){
        NSAssert(!self.fetchedResultsController.sectionNameKeyPath, @"sectionKeyPath is not nil, don't know which section to return");
        id<NSFetchedResultsSectionInfo> section = [self.fetchedResultsController.sections objectAtIndex:0];
        return section;
    }
    else {
        NSAssert(NO, @"not handle managed type for tableviewBuilder");
        return nil;
    }
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    _fetchedResultsController = fetchedResultsController;
    _fetchedResultsController.delegate = self.sectionItem.tableViewBuilder;
}

- (NSArray *)filterRowItemsUsingPredicate:(NSPredicate *)predicate {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"You can't call %@ when section item is backed by NSFetchedResultsController", NSStringFromSelector(_cmd)] userInfo:nil];
}

- (void)insertObject:(TMRowItem *)anObject inRowItemsAtIndex:(NSUInteger)idx {
    [NSException raise:NSInternalInconsistencyException format:@"You can't call %@ when section item is backed by NSFetchedResultsController", NSStringFromSelector(_cmd)];
}

- (void)insertRowItems:(NSArray *)RowItemsArray atIndexes:(NSIndexSet *)indexes {
    [NSException raise:NSInternalInconsistencyException format:@"You can't call %@ when section item is backed by NSFetchedResultsController", NSStringFromSelector(_cmd)];
}

- (void)removeObjectFromRowItemsAtIndex:(NSUInteger)idx {
    [NSException raise:NSInternalInconsistencyException format:@"You can't call %@ when section item is backed by NSFetchedResultsController", NSStringFromSelector(_cmd)];
}

- (void)removeRowItemsAtIndexes:(NSIndexSet *)indexes {
    [NSException raise:NSInternalInconsistencyException format:@"You can't call %@ when section item is backed by NSFetchedResultsController", NSStringFromSelector(_cmd)];
}

- (void)replaceObjectInRowItemsAtIndex:(NSUInteger)idx withObject:(TMRowItem *)anObject {
    [NSException raise:NSInternalInconsistencyException format:@"You can't call %@ when section item is backed by NSFetchedResultsController", NSStringFromSelector(_cmd)];
}

- (void)replaceRowItemsAtIndexes:(NSIndexSet *)indexes withRowItems:(NSArray *)lowerRowItemsArray {
    
    [NSException raise:NSInternalInconsistencyException format:@"You can't call %@ when section item is backed by NSFetchedResultsController", NSStringFromSelector(_cmd)];
}

- (void)addToRowItems:(TMRowItem *)anObject {
    [NSException raise:NSInternalInconsistencyException format:@"You can't call %@ when section item is backed by NSFetchedResultsController", NSStringFromSelector(_cmd)];
}

- (void)removeFromRowItems:(TMRowItem *)rowItems {
    [NSException raise:NSInternalInconsistencyException format:@"You can't call %@ when section item is backed by NSFetchedResultsController", NSStringFromSelector(_cmd)];
}
@end
