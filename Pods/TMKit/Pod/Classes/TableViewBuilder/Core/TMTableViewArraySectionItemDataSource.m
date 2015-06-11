//
//  TMTableViewRowItemDataSource.m
//  Pods
//
//  Created by Zitao Xiong on 6/1/15.
//
//

#import "TMTableViewArraySectionItemDataSource.h"
#import "TMSectionItem.h"

@interface TMTableViewArraySectionItemDataSource()
@property (nonatomic, strong) NSMutableArray *sectionItems;
@property (nonatomic, strong) NSArray *sectionIndexTitles;
@end

@implementation TMTableViewArraySectionItemDataSource
@synthesize delegate = _delegate;

- (NSMutableArray *)sectionItems {
    if (!_sectionItems) {
        _sectionItems = [NSMutableArray array];
    }
    
    return _sectionItems;
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}
#pragma mark - TMSectionItem Accessor

- (void)addToSectionItems:(TMSectionItem *)sectionItemsObject {
    [self.sectionItems addObject:sectionItemsObject];
    [self didInsertSectionItem:sectionItemsObject];
}

- (void)removeFromSectionItems:(TMSectionItem *)sectionItemsObject {
    [self.sectionItems removeObject:sectionItemsObject];
    [self didRemoveSectionItem:sectionItemsObject];
}

- (NSUInteger)countOfSectionItems {
    return [self.sectionItems count];
}

- (TMSectionItem *)objectInSectionItemsAtIndex:(NSUInteger)idx {
    TMSectionItem *item = [self.sectionItems objectAtIndex:idx];
    if ([self.delegate respondsToSelector:@selector(didFetchSectionItem:)]) {
        [self.delegate didFetchSectionItem:item];
    }
    
    return item;
}

- (void)insertObject:(TMSectionItem *)aTMSectionItem inSectionItemsAtIndex:(NSUInteger)idx {
    [self.sectionItems insertObject:aTMSectionItem atIndex:idx];
    [self didInsertSectionItem:aTMSectionItem];
}

- (void)insertSectionItems:(NSArray *)sectionItemsArray atIndexes:(NSIndexSet *)indexes {
    [self.sectionItems insertObjects:sectionItemsArray atIndexes:indexes];
    [sectionItemsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self didInsertSectionItem:obj];
    }];
}

- (void)removeObjectFromSectionItemsAtIndex:(NSUInteger)idx {
    TMSectionItem *obj = [self.sectionItems objectAtIndex:idx];
    [self.sectionItems removeObjectAtIndex:idx];
    [self didRemoveSectionItem:obj];
}

- (void)removeSectionItemsAtIndexes:(NSIndexSet *)indexes {
    NSArray *removedObjects = [self.sectionItems objectsAtIndexes:indexes];
    [self.sectionItems removeObjectsAtIndexes:indexes];
    [removedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self didRemoveSectionItem:obj];
    }];
}

- (void)replaceObjectInSectionItemsAtIndex:(NSUInteger)idx withObject:(TMSectionItem *)aTMSectionItem {
    [self.sectionItems replaceObjectAtIndex:idx withObject:aTMSectionItem];
    [self didInsertSectionItem:aTMSectionItem];
}

- (void)replaceSectionItemsAtIndexes:(NSIndexSet *)indexes withSectionItems:(NSArray *)sectionItemsArray {
    [self.sectionItems replaceObjectsAtIndexes:indexes withObjects:sectionItemsArray];
    [sectionItemsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self didInsertSectionItem:obj];
    }];
}

- (NSUInteger)indexOfSectionItem:(TMSectionItem *)sectionItem {
    return [self.sectionItems indexOfObject:sectionItem];
}

- (void)removeAllSectionItems {
    [self.sectionItems removeAllObjects];
}

- (void)didInsertSectionItem:(TMSectionItem *)object {
    if ([self.delegate respondsToSelector:@selector(didInsertSectionItem:)]) {
        [self.delegate didInsertSectionItem:object];
    }
}

- (void)didRemoveSectionItem:(TMSectionItem *)object {
    if ([self.delegate respondsToSelector:@selector(didRemoveSectionItem:)]) {
        [self.delegate didRemoveSectionItem:object];
    }
}
@end
