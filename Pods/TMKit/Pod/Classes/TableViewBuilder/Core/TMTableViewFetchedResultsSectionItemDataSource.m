//
//  TMTableViewFetchedResultsRowItemDataSource.m
//  Pods
//
//  Created by Zitao Xiong on 6/1/15.
//
//

#import "TMTableViewFetchedResultsSectionItemDataSource.h"
#import "TMSectionItem.h"

@interface TMTableViewFetchedResultsSectionItemDataSource()
@property (nonatomic, strong) NSMutableArray *sectionItems;
@end

@implementation TMTableViewFetchedResultsSectionItemDataSource
@synthesize delegate = _delegate;

- (NSMutableArray *)sectionItems {
    if (!_sectionItems) {
        _sectionItems = [NSMutableArray array];
    }
    return _sectionItems;
}

#pragma mark -
- (NSUInteger)countOfSectionItems {
    return self.fetchedResultsController.sections.count;
}

- (TMSectionItem *)objectInSectionItemsAtIndex:(NSUInteger)idx {
    TMSectionItem *sectionItem;
    
    if (idx < self.sectionItems.count) {
        sectionItem = self.sectionItems[idx];
    }
    else if (idx == self.sectionItems.count) {
        sectionItem = [self insertedFetchedResultsSectionItemAtIndex:idx];
    }
    else {
        //created section item prior to idx
        for (NSUInteger i = 0; i < idx; i++) {
            [self insertedFetchedResultsSectionItemAtIndex:i];
        }
        
        sectionItem = [self insertedFetchedResultsSectionItemAtIndex:idx];
    }
    
    NSParameterAssert(sectionItem);
    
    if ([self.delegate respondsToSelector:@selector(didFetchSectionItem:)]) {
        [self.delegate didFetchSectionItem:sectionItem];
    }
    
    return sectionItem;
}

- (TMSectionItem *)insertedFetchedResultsSectionItemAtIndex:(NSUInteger)index {
    TMSectionItem *sectionItem = [TMSectionItem sectionItemWithType:TMSectionItemTypeFetchedResultsController];
    
    //table view builder implemented this delegate to make sure
    //tableViewBuilder is set properly before fetchResultsController is set.
    if ([self.delegate respondsToSelector:@selector(fetchedResultsRowItemDataSource:didCreatedFetchedResultsSectionItem:)]) {
        [self.delegate fetchedResultsRowItemDataSource:self didCreatedFetchedResultsSectionItem:sectionItem];
    }
    
    [self.sectionItems insertObject:sectionItem atIndex:index];
    sectionItem.fetchedResultsController = self.fetchedResultsController;
    return sectionItem;
}

- (NSUInteger)indexOfSectionItem:(TMSectionItem *)sectionItem {
    return [self.sectionItems indexOfObject:sectionItem];
//    NSArray *allKeys = [self.sectionItemsDictionary allKeysForObject:sectionItem];
//    
//    if (allKeys.count == 1) {
//        NSUInteger index = [allKeys.firstObject unsignedIntegerValue];
//        return index;
//    }
//    else if (allKeys.count == 0) {
//        return NSNotFound;
//    }
//    else {
//        NSAssert(false, @"duplicated key found");
//        return -1;
//    }
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.fetchedResultsController sectionForSectionIndexTitle:title
                                                              atIndex:index];
}

- (NSArray *)sectionIndexTitles {
    return [self.fetchedResultsController sectionIndexTitles];
}

- (void)removeAllSectionItems {
    [self.sectionItems removeAllObjects];
}
@end
