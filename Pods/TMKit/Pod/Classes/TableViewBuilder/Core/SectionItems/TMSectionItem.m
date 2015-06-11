//
//  TMSectionItem.m
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

#import "TMSectionItem.h"
#import "TMRowItem+Protected.h"
#import "TMTableViewBuilder.h"
#import "FBKVOController+Binding.h"
#import "TMSectionItem+Protected.h"
#import "EXTKeyPathCoding.h"
#import "TMSectionItemArrayRowItemDataSource.h"
#import "TMSectionItemFetchedResultsRowItemDataSource.h"


@interface TMSectionItem ()<TMSectionItemRowDataSourceDelegate>
//protected
//see "TMSectionItem+Protected.h"
@end

@implementation TMSectionItem
- (instancetype)init {
    return [self initWithType:TMSectionItemTypeArray];
}

+ (instancetype)sectionItemWithType:(TMSectionItemType)type {
    id item = [(TMSectionItem *)[self alloc] initWithType:type];
    return item;
}

- (instancetype)initWithType:(TMSectionItemType)type {
    self = [super init];
    if (self) {
        self.type = type;
        if (self.type == TMSectionItemTypeArray) {
            self.rowDataSource = [[TMSectionItemArrayRowItemDataSource alloc] init];
        }
        else if (self.type == TMSectionItemTypeFetchedResultsController) {
            self.rowDataSource = [[TMSectionItemFetchedResultsRowItemDataSource alloc] init];
        }
        self.rowDataSource.delegate = self;
        self.rowDataSource.sectionItem = self;
    }
    return self;
}
#pragma mark - TMSectionItemRowDataSourceDelegate
- (void)didInsertRowItem:(TMRowItem *)object {
    object.sectionItem = self;
    [self.tableViewBuilder addReuseIdentifierToRegister:object.reuseIdentifier];
}

- (void)didRemoveRowItem:(TMRowItem *)object {
    
}
#pragma mark - TMRowItem Accessor <KVO>

- (void)addRowItem:(TMRowItem *)rowItem {
    [self.rowDataSource addToRowItems:rowItem];
}

- (void)removeFromRowItems:(TMRowItem *)rowItem {
    [self.rowDataSource removeFromRowItems:rowItem];
}

- (void)removeRowItem:(TMRowItem *)aRowItem {
    [self.rowDataSource removeFromRowItems:aRowItem];
}

- (NSUInteger)countOfRowItems {
    return self.rowDataSource.countOfRowItems;
}

- (NSInteger)numberOfRows {
    return self.rowDataSource.countOfRowItems;
}

- (TMRowItem *)objectInRowItemsAtIndex:(NSUInteger)idx {
    return [self.rowDataSource objectInRowItemsAtIndex:idx];
}

- (void)insertObject:(TMRowItem *)rowItem inRowItemsAtIndex:(NSUInteger)idx {
    [self.rowDataSource insertObject:rowItem inRowItemsAtIndex:idx];
}

- (void)insertRowItems:(NSArray *)items atIndexes:(NSIndexSet *)indexes {
    [self.rowDataSource insertRowItems:items atIndexes:indexes];
}

- (void)removeObjectFromRowItemsAtIndex:(NSUInteger)idx {
    [self.rowDataSource removeObjectFromRowItemsAtIndex:idx];
}

- (void)removeRowItemAtIndex:(NSUInteger)index {
    [self.rowDataSource removeObjectFromRowItemsAtIndex:index];
}

- (void)removeRowItemsAtIndexes:(NSIndexSet *)indexes {
    [self.rowDataSource removeRowItemsAtIndexes:indexes];
}

- (void)replaceObjectInRowItemsAtIndex:(NSUInteger)idx withObject:(TMRowItem *)rowItem {
    [self.rowDataSource replaceObjectInRowItemsAtIndex:idx withObject:rowItem];
}

- (void)replaceRowItemsAtIndexes:(NSIndexSet *)indexes withRowItems:(NSArray *)items {
    [self.rowDataSource replaceRowItemsAtIndexes:indexes withRowItems:items];
}

- (TMRowItem *)rowItemAtIndex:(NSUInteger)index {
    return self[index];
}

- (NSUInteger)indexOfRowItem:(TMRowItem *)rowItem {
    return [self.rowDataSource indexOfRowItem:rowItem];
}

#pragma mark - Keyed Subscript
- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectInRowItemsAtIndex:index];
}

- (void)setObject:(TMRowItem *)obj atIndexedSubscript:(NSUInteger)index {
    NSParameterAssert([obj isKindOfClass:[TMRowItem class]]);
    [self insertObject:obj inRowItemsAtIndex:index];
}

#pragma mark - NSFechtedResultsController
- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    [self.rowDataSource setFetchedResultsController:fetchedResultsController];
}

- (NSFetchedResultsController *)fetchedResultsController {
    return self.rowDataSource.fetchedResultsController;
}

- (id<NSFetchedResultsSectionInfo>)sectionInfo {
    return self.rowDataSource.sectionInfo;
}

- (CGFloat)estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}
#pragma mark -
- (void)removeFromTableViewAnimated:(BOOL)animated {
    [self.tableViewBuilder removeSectionItem:self];
    if (self.section != NSNotFound) {
        UITableViewRowAnimation animation = animated ? UITableViewRowAnimationFade : UITableViewRowAnimationNone;
        [self.tableViewBuilder.tableView deleteSections:[NSIndexSet indexSetWithIndex:self.section] withRowAnimation:animation];
    }
}

- (void)removeFromTableView {
    [self removeFromTableViewAnimated:NO];
}

#pragma mark -
- (UIView *)headerView {
    return nil;
}

+ (NSString *)cellReuseIdentifierForHeader {
    return nil;
}

+ (NSString *)cellReuseIdentifierForFooter {
    return nil;
}

- (UIView *)viewForHeader {
    if (!_viewForHeader) {
        NSString *identifier = [[self class] cellReuseIdentifierForHeader];
        UITableViewHeaderFooterView *cell = [self.tableViewBuilder.tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
        if (!cell && identifier) {
            [self.tableViewBuilder.tableView registerClass:NSClassFromString(identifier) forHeaderFooterViewReuseIdentifier:identifier];
            cell = [self.tableViewBuilder.tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
        }
        _viewForHeader = cell;
    }
    
    if ([_viewForHeader isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *cell = (UITableViewHeaderFooterView *)_viewForHeader;
        [self prepareForReuse:cell];
        cell.backgroundView = self.backgroundViewForHeader;
    }
    
    return _viewForHeader;
}

- (UIView *)viewForFooter {
    if (!_viewForFooter) {
        NSString *identifier = [[self class] cellReuseIdentifierForFooter];
        UITableViewHeaderFooterView *cell = [self.tableViewBuilder.tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
        if (!cell && identifier) {
            [self.tableViewBuilder.tableView registerClass:NSClassFromString(identifier) forHeaderFooterViewReuseIdentifier:identifier];
            cell = [self.tableViewBuilder.tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
        }
        _viewForFooter = cell;
    }
    
    if ([_viewForFooter isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *cell = (UITableViewHeaderFooterView *)_viewForFooter;
        [self prepareForReuse:cell];
        cell.backgroundView = self.backgroundViewForFooter;
    }
    
    return _viewForFooter;
}

- (void)prepareForReuse:(UITableViewHeaderFooterView *)view {
    [self unbind];
    [view unbind];
}

- (void)setTitleForHeader:(NSString *)titleForHeader {
    [self willChangeValueForKey:@keypath(self.titleForHeader)];
    _titleForHeader = titleForHeader;
    self.heightForHeader = 30;
    [self didChangeValueForKey:@keypath(self.titleForHeader)];
}

- (void)setTitleForFooter:(NSString *)titleForFooter {
    [self willChangeValueForKey:@keypath(self.titleForFooter)];
    _titleForFooter = titleForFooter;
    self.heightForFooter = 30;
    [self didChangeValueForKey:@keypath(self.titleForFooter)];
}
#pragma mark - UITableViewDataSource
#pragma mark - reload
- (void)reloadSectionWithAnimation:(UITableViewRowAnimation)animation {
    [self.tableViewBuilder.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.section] withRowAnimation:animation];
}

#pragma mark - UITableViewDelegate
- (void)willDisplayHeaderView:(UIView *)view NS_AVAILABLE_IOS(6_0) {
}

- (void)willDisplayFooterView:(UIView *)view NS_AVAILABLE_IOS(6_0) {
}

- (void)didEndDisplayingHeaderView:(UIView *)view NS_AVAILABLE_IOS(6_0) {
    [self unbind];
}

- (void)didEndDisplayingFooterView:(UIView *)view NS_AVAILABLE_IOS(6_0) {
    [self unbind];
}

#pragma mark - Convenient Methods
- (UITableView *)tableView {
    return self.tableViewBuilder.tableView;
}

- (NSInteger)section {
    return [self.tableViewBuilder indexOfSection:self];
}

#pragma mark - Notify TableView
- (void)insertObject:(TMRowItem *)object inMutableRowItemsAtIndex:(NSUInteger)index withRowAnimation:(UITableViewRowAnimation)animation {
    NSParameterAssert(self.tableView);
    [self insertObject:object inRowItemsAtIndex:index];
    [self.tableView insertRowsAtIndexPaths:@[object.indexPath] withRowAnimation:animation];
}

- (void)removeObjectFromMutableRowItemsAtIndex:(NSUInteger)index withRowAnimation:(UITableViewRowAnimation)animation {
    NSParameterAssert(self.tableView);
    TMRowItem *rowItem = [self rowItemAtIndex:index];
    NSIndexPath *indexPath = rowItem.indexPath;
    [self removeRowItemAtIndex:index];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:animation];
}

#pragma mark - Cell
//set height will also set the height for estimatedHeight.
//because the default delegate implemented estimatedHeightForXXX, if not estimatedHeight is not set
//viewForXXX will not be called.
- (void)setHeightForFooter:(CGFloat)heightForFooter {
    _heightForFooter = heightForFooter;
    self.estimatedHeightForFooter = heightForFooter;
}

- (void)setHeightForHeader:(CGFloat)heightForHeader {
    _heightForHeader = heightForHeader;
    self.estimatedHeightForHeader = heightForHeader;
}

- (UIColor *)backgroundColorForHeader {
    return self.backgroundViewForHeader.backgroundColor;
}

- (void)setBackgroundColorForHeader:(UIColor *)backgroundColorForHeader {
    self.backgroundViewForHeader = [[UIView alloc] init];
    self.backgroundViewForHeader.backgroundColor = backgroundColorForHeader;
}

- (UIColor *)backgroundColorForFooter {
    return self.backgroundViewForFooter.backgroundColor;
}

- (void)setBackgroundColorForFooter:(UIColor *)backgroundColorForFooter {
    self.backgroundViewForFooter = [[UIView alloc] init];
    self.backgroundViewForFooter.backgroundColor = backgroundColorForFooter;
}

#pragma mark - Collection Methods
- (void)tm_each:(void (^)(id rowItem))block {
    for (NSUInteger i = 0; i < [self countOfRowItems]; i++) {
        TMRowItem *rowItem = [self rowItemAtIndex:i];
        block(rowItem);
    }
}

#pragma mark - Predicate
- (NSArray *)filterRowItemsUsingPredicate:(NSPredicate *)predicate {
    return [self.rowDataSource filterRowItemsUsingPredicate:predicate];
}

#pragma mark - Copy 


- (id)copyWithZone:(NSZone *)zone
{
    id theCopy = [(TMSectionItem *)[[self class] allocWithZone:zone] initWithType:self.type];  // use designated initializer
    
//    [theCopy setTableViewBuilder:[self.tableViewBuilder copy]];// no builder
//    [theCopy setSection:self.section];
//    [theCopy setFetchedResultsController:[self.fetchedResultsController copy]];
    [theCopy setTitleForHeader:[self.titleForHeader copy]];
    [theCopy setTitleForFooter:[self.titleForFooter copy]];
    [theCopy setHeightForHeader:self.heightForHeader];
    [theCopy setHeightForFooter:self.heightForFooter];
    [theCopy setEstimatedHeightForHeader:self.estimatedHeightForHeader];
    [theCopy setEstimatedHeightForFooter:self.estimatedHeightForFooter];
    
    [theCopy setViewForHeader:[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.viewForHeader]]];
    [theCopy setViewForFooter:[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.viewForFooter]]];
    
    [theCopy setBackgroundViewForHeader:[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.backgroundViewForHeader]]];
    [theCopy setBackgroundViewForFooter:[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.backgroundViewForFooter]]];
    
    [theCopy setBackgroundColorForHeader:[self.backgroundColorForHeader copy]];
    [theCopy setBackgroundColorForFooter:[self.backgroundColorForFooter copy]];
    
    return theCopy;
}
@end
