//
//  TMTableViewBuilder.m
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

#import "TMTableViewBuilder.h"
#import "TMTableViewArraySectionItemDataSource.h"
#import "TMSectionItem+Protected.h"
#import "TMSectionItem.h"
#import "TMTableViewDelegate.h"
#import "TMTableViewDataSource.h"
#import "TMLog.h"
#import "TMRowItem.h"
#import "TMTableViewFetchedResultsSectionItemDataSource.h"
#import "TMTableViewFetchedResultConfiguration.h"
#import "TMSearchController.h"
#import "TMTableViewSearchResultsController.h"
#import "TMSimpleTableViewController.h"

static void (^_globalTableViewConfigurationBlock)(UITableView *tableView);
//static NSMutableDictionary *registerredClassMapping = nil;
static NSMutableDictionary *defaultRegisterredClassMapping = nil;

@interface TMTableViewBuilder ()<TMTableViewSectionItemDataSourceDelegate>
@property (nonatomic, strong) NSObject<TMTableViewSectionItemDataSource> *sectionItemDataSource;
@property (nonatomic, strong) NSMutableDictionary *configurationsMapping;
@property (nonatomic, strong) NSMutableSet *reuseIdentifiersToRegister;
@property (nonatomic, strong) NSMutableDictionary *registerredClassMapping;;
@property (nonatomic, assign, getter = isConfigured) BOOL configured;
@end

@implementation TMTableViewBuilder
@synthesize tableViewDataSource = _tableViewDataSource;
@synthesize tableViewDelegate = _tableViewDelegate;

+ (void)initialize {
//    registerredClassMapping = [NSMutableDictionary dictionary];
    defaultRegisterredClassMapping = [NSMutableDictionary dictionary];
    [self registerDefaultClass:[TMSearchController class] forType:TMTableViewBuilderClassTypeSearchController];
    [self registerDefaultClass:[TMTableViewSearchResultsController class] forType:TMTableViewBuilderClassTypeSearchResultsController];
}

- (instancetype)initWithTableView:(UITableView *)tableView {
    return [self initWithTableView:tableView managedType:TMTableViewBuilderManagedTypeArray];
}

- (instancetype)initWithTableView:(UITableView *)tableView managedType:(TMTableViewBuilderManagedType)managedType {
    return [self initWithTableView:tableView managedType:managedType tableViewDataSourceOverride:nil tableViewDelegateOverride:nil];
}

- (instancetype)initWithTableView:(UITableView *)tableView managedType:(TMTableViewBuilderManagedType)managedType tableViewDataSourceOverride:(id <TMTableViewDataSource> )datasource tableViewDelegateOverride:(id <UITableViewDelegate> )delegate {
    self = [super init];
    if (self) {
        _managedType = managedType;
        if (_managedType == TMTableViewBuilderManagedTypeArray) {
            self.sectionItemDataSource = [TMTableViewArraySectionItemDataSource new];
        }
        else {
            self.sectionItemDataSource = [TMTableViewFetchedResultsSectionItemDataSource new];
        }
        self.sectionItemDataSource.delegate = self;
        self.tableViewDelegate.delegate = delegate;
        self.tableViewDataSource.dataSource = datasource;
        
        self.configurationsMapping = [NSMutableDictionary dictionary];
        self.registerredClassMapping = [NSMutableDictionary dictionary];
        self.tableView = tableView;
    }
    
    return self;
}

- (void)didFetchSectionItem:(TMSectionItem *)object {
    object.tableViewBuilder = self;
    if (self.didFetchSectionItemBlock) {
        self.didFetchSectionItemBlock(object);
    }
}

- (void)didInsertSectionItem:(TMSectionItem *)sectionItem {
    for (NSInteger i = 0; i < sectionItem.numberOfRows; i++) {
        TMRowItem *rowItem = [sectionItem rowItemAtIndex:i];
        [self addReuseIdentifierToRegister:[rowItem reuseIdentifier]];
    }
}

- (void)fetchedResultsRowItemDataSource:(TMTableViewFetchedResultsSectionItemDataSource *)dataSrouce didCreatedFetchedResultsSectionItem:(TMSectionItem *)sectionItem {
    sectionItem.tableViewBuilder = self;
}
#pragma mark -
- (NSMutableDictionary *)configurationsMapping {
    if (!_configurationsMapping) {
        _configurationsMapping = [[NSMutableDictionary alloc] init];
    }
    
    return _configurationsMapping;
}

- (NSMutableSet *)reuseIdentifiersToRegister {
    if (!_reuseIdentifiersToRegister) {
        _reuseIdentifiersToRegister = [NSMutableSet set];
    }
    
    return _reuseIdentifiersToRegister;
}
#pragma mark - KVC
- (void)insertObject:(TMSectionItem *)object inSectionItemsAtIndex:(NSUInteger)index {
    [self.sectionItemDataSource insertObject:object inSectionItemsAtIndex:index];
}

- (void)replaceObjectInSectionItemsAtIndex:(NSUInteger)index withObject:(TMSectionItem *)object {
    [self.sectionItemDataSource replaceObjectInSectionItemsAtIndex:index withObject:object];
}

- (void)removeObjectFromSectionItemsAtIndex:(NSUInteger)index {
    [self.sectionItemDataSource removeObjectFromSectionItemsAtIndex:index];
}

- (void)removeAllSectionItems {
    [self.sectionItemDataSource removeAllSectionItems];
}

- (void)removeRowItemAtIndexPath:(NSIndexPath *)indexPath {
    TMSectionItem *sectionItem = [self.sectionItemDataSource objectInSectionItemsAtIndex:indexPath.section];
    [sectionItem removeRowItemAtIndex:indexPath.row];
}

- (void)removeSectionItem:(TMSectionItem *)item {
    NSInteger index = [self.sectionItemDataSource indexOfSectionItem:item];
    if (index != NSNotFound) {
        [self removeObjectFromSectionItemsAtIndex:index];
    }
}

- (void)insertSectionItems:(NSArray *)sectionItemsArray atIndexes:(NSIndexSet *)indexes {
    [self.sectionItemDataSource insertSectionItems:sectionItemsArray atIndexes:indexes];
}
#pragma mark - kyed subscript
- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self.sectionItemDataSource objectInSectionItemsAtIndex:index];
}

- (void)setObject:(TMSectionItem *)obj atIndexedSubscript:(NSUInteger)index {
    NSParameterAssert([obj isKindOfClass:[TMSectionItem class]]);
    [self insertObject:obj inSectionItemsAtIndex:index];
}

#pragma mark -

- (NSInteger)numberOfSections {
    return [self.sectionItemDataSource countOfSectionItems];
}

- (TMSectionItem *)sectionItemAtIndex:(NSInteger)index {
    return [self.sectionItemDataSource objectInSectionItemsAtIndex:index];
}

- (TMRowItem *)rowItemAtIndexPath:(NSIndexPath *)indexPath {
    TMSectionItem *sectionItem = [self sectionItemAtIndex:indexPath.section];
    TMRowItem *rowItem = [sectionItem rowItemAtIndex:indexPath.row];
    return rowItem;
}

- (void)addSectionItem:(TMSectionItem *)sectionItem {
    NSParameterAssert([sectionItem isKindOfClass:[TMSectionItem class]]);
    [self insertObject:sectionItem inSectionItemsAtIndex:self.numberOfSections];
}

- (NSUInteger)indexOfSection:(TMSectionItem *)section {
    return [self.sectionItemDataSource indexOfSectionItem:section];
}

- (TMTableViewDataSource *)tableViewDataSource {
    if (!_tableViewDataSource) {
        _tableViewDataSource = [[TMTableViewDataSource alloc] initWithTableViewBuilder:self];
    }
    return _tableViewDataSource;
}

- (TMTableViewDelegate *)tableViewDelegate {
    if (!_tableViewDelegate) {
        _tableViewDelegate = [[TMTableViewDelegate alloc] initWithTableViewBuilder:self];
    }
    return _tableViewDelegate;
}

- (void)registerTableViewCellForTableView:(UITableView *)tableView {
    NSSet *identifiers = self.reuseIdentifiersToRegister;
    
    for (NSString *reuseIdentifier in identifiers) {
        [tableView registerNib:[UINib nibWithNibName:reuseIdentifier bundle:nil] forCellReuseIdentifier:reuseIdentifier];
    }
}

- (void)addReuseIdentifierToRegister:(NSString *)reusedIdentifier {
    [self.reuseIdentifiersToRegister addObject:reusedIdentifier];
}

- (void)configure {
    NSParameterAssert(self.tableView);
    self.configured = YES;
    
    [self reloadData];
    
    [self registerTableViewCellForTableView:self.tableView];
    
    if (_globalTableViewConfigurationBlock) {
        _globalTableViewConfigurationBlock(self.tableView);
    }
}

- (void)reloadData {
    if (self.reloadBlock) {
        self.reloadBlock(self);
    }
    [self.tableView reloadData];
}

+ (void)setGlobalTableViewConfiguration:(void (^)(UITableView *))configuration {
    _globalTableViewConfigurationBlock = configuration;
}

- (void)setTableView:(UITableView *)tableView {
    _tableView = tableView;
    _tableView.delegate = self.tableViewDelegate;
    _tableView.dataSource = self.tableViewDataSource;
}
#pragma mark - Section Index Titles 
- (void)setSectionIndexTitles:(NSArray *)sectionIndexTitles {
    if ([self.sectionItemDataSource respondsToSelector:@selector(setSectionIndexTitles:)]) {
        [self.sectionItemDataSource setSectionIndexTitles:sectionIndexTitles];
    }
    else {
        NSAssert(NO, @"do not support setting index titles");
    }
}

- (NSArray *)sectionIndexTitles {
    return [self.sectionItemDataSource sectionIndexTitles];
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.sectionItemDataSource sectionForSectionIndexTitle:title atIndex:index];
}
#pragma mark - Collection Methods
- (NSArray *)visibleRowItems {
    NSArray *indexPathForVisibleRows = [self.tableView indexPathsForVisibleRows];
    NSMutableArray *rows = [NSMutableArray array];
    [indexPathForVisibleRows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [rows addObject:[self rowItemAtIndexPath:obj]];
    }];
    
    return rows.copy;
}

- (void)reloadVisibleRowsWithRowAnimation:(UITableViewRowAnimation)animation {
    NSArray *indexPathes = [self.tableView indexPathsForVisibleRows];
    
    [self.tableView reloadRowsAtIndexPaths:indexPathes withRowAnimation:animation];
}

- (void)tm_eachRowItem:(void (^)(id))block {
    [self tm_eachSectionItem:^(TMSectionItem *sectionItem) {
        [sectionItem tm_each:^(id rowItem) {
            block(rowItem);
        }];
    }];
}

- (void)tm_eachSectionItem:(void (^)(id))block {
    for (NSUInteger i = 0; i < [self numberOfSections]; i++) {
        TMSectionItem *sectionItem = [self sectionItemAtIndex:i];
        block(sectionItem);
    }
}

#pragma mark - Class registration
+ (void)registerDefaultClass:(Class)klass forType:(TMTableViewBuilderClassType)type {
    defaultRegisterredClassMapping[@(type)] = klass;
}

//+ (void)registerClass:(Class)klass forType:(TMTableViewBuilderClassType)type {
//    registerredClassMapping[@(type)] = klass;
//}

- (void)registerClass:(Class)klass forType:(TMTableViewBuilderClassType)type {
    self.registerredClassMapping[@(type)] = klass;
}

//+ (void)unregisterClass:(Class)kclass forType:(TMTableViewBuilderClassType)type {
//    [registerredClassMapping removeObjectForKey:@(type)];
//}

- (Class)classForType:(TMTableViewBuilderClassType)type {
    if (self.registerredClassMapping[@(type)]) {
        return self.registerredClassMapping[@(type)];
    }
    else {
        return defaultRegisterredClassMapping[@(type)];
    }
}

#pragma mark - Core Data 
- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    TMTableViewFetchedResultsSectionItemDataSource *datasource = (TMTableViewFetchedResultsSectionItemDataSource *)self.sectionItemDataSource;
    datasource.fetchedResultsController = fetchedResultsController;
}

- (NSFetchedResultsController *)fetchedResultsController {
    TMTableViewFetchedResultsSectionItemDataSource *datasource = (TMTableViewFetchedResultsSectionItemDataSource *)self.sectionItemDataSource;
    return datasource.fetchedResultsController;
}

- (void)registerConfiguration:(TMTableViewFetchedResultConfiguration *)configuration forMangedObjectIdentifier:(NSString *)identifer {
    self.configurationsMapping[identifer] = configuration;
//    Class<TMRowItemProtocol> rowItemClass = [configuration rowItemClass];
//    if ([rowItemClass reuseIdentifier]) {
//        [self addReuseIdentifierToRegister:[rowItemClass reuseIdentifier]];
//    }
}

- (TMTableViewFetchedResultConfiguration *)configurationForManagedObjectIdentifier:(NSString *)identifier {
    return self.configurationsMapping[identifier];
}

#pragma mark - NSFetchedResultControllerDelegate
- (NSUInteger)sectionForFetchedResultsController:(NSFetchedResultsController*)controller {
    NSUInteger section = NSNotFound;
    __block TMSectionItem *foundSectionItem = nil;
    [self tm_eachSectionItem:^(TMSectionItem *sectionItem) {
        if (sectionItem.type == TMSectionItemTypeFetchedResultsController && sectionItem.fetchedResultsController == controller) {
            foundSectionItem = sectionItem;
            return ;
        }
    }];
    
    section = [self indexOfSection:foundSectionItem];
    
    return section;
}

- (NSIndexPath *)actualIndexPathForIndexPath:(NSIndexPath *)indexPath withController:(NSFetchedResultsController *)controller {
    NSUInteger section = [self sectionForFetchedResultsController:controller];
    return [NSIndexPath indexPathForRow:indexPath.row inSection:section];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    //the actual section for managed type array is not correct when returned from NSFetchedResultsControllerDelegate
    if (self.managedType == TMTableViewBuilderManagedTypeArray) {
        indexPath = [self actualIndexPathForIndexPath:indexPath withController:controller];
        newIndexPath = [self actualIndexPathForIndexPath:indexPath withController:controller];
    }
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            TMRowItem *rowItem = [self rowItemAtIndexPath:newIndexPath];
            [rowItem didManagedObjectUpdated:anObject];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            TMRowItem *rowItem = [self rowItemAtIndexPath:indexPath];
            [rowItem didManagedObjectUpdated:anObject];
            break;
        }
        default: {
            break;
        }
            
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    NSParameterAssert(self.managedType == TMTableViewBuilderManagedTypeFetchedResultsController);
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - UISearchController

- (void)initializeSearchControllerWithViewController:(UIViewController *)viewController {
    Class SearchControllerClass = [self classForType:TMTableViewBuilderClassTypeSearchController];
    Class SearchResultsControllerClass = [self classForType:TMTableViewBuilderClassTypeSearchResultsController];
    NSParameterAssert([SearchControllerClass isSubclassOfClass:[UISearchController class]]);
    NSParameterAssert([SearchResultsControllerClass isSubclassOfClass:[UIViewController class]]);
    NSParameterAssert([SearchResultsControllerClass conformsToProtocol:@protocol(TMSimpleTableViewController)]);
    NSParameterAssert([SearchResultsControllerClass conformsToProtocol:@protocol(UISearchResultsUpdating)]);
    
    self.searchResultsController = [(UIViewController<TMSimpleTableViewController, UISearchResultsUpdating, TMSearchFilterring> *) [SearchResultsControllerClass alloc] init];
    self.searchResultsController.filterringTableViewBuilder = self;
    
    self.searchController = [(UISearchController *) [SearchControllerClass alloc] initWithSearchResultsController:self.searchResultsController];
    
    self.searchController.searchResultsUpdater = self.searchResultsController;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    viewController.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit];
}

@end

@implementation TMTableViewBuilder (SectionItemAddition)

- (TMSectionItem *)addedSectionItem {
    TMSectionItem *section = [TMSectionItem new];
    [self addSectionItem:section];
    return section;
}

@end