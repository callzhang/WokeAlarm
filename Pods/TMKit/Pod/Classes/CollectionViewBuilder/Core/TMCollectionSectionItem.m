//
//  TMCollectionSectionItem.m
//  Pods
//
//  Created by Zitao Xiong on 5/5/15.
//
//

#import "TMCollectionSectionItem.h"
#import "TMCollectionItem.h"
#import "TMCollectionViewBuilder.h"

@interface TMCollectionSectionItem ()
@property (nonatomic, strong) NSMutableArray *collectionItems;
@end

@implementation TMCollectionSectionItem

- (instancetype)init {
    self = [super init];
    if (self) {
        self.collectionItems = [NSMutableArray array];
    }
    return self;
}

- (NSUInteger)section {
    return [self.collectionViewBuilder indexOfCollectionSectionItem:self];
}

///////  collectionItems  ///////
- (void)addCollectionItem:(TMCollectionItem *)aCollectionItem {
    [[self collectionItems] addObject:aCollectionItem];
    aCollectionItem.sectionItem = self;
    [self.collectionViewBuilder addCellReuseIdentifierForRegistration:aCollectionItem.reuseIdentifier];
}

- (void)removeCollectionItem:(TMCollectionItem *)aCollectionItem {
    [[self collectionItems] removeObject:aCollectionItem];
}

- (NSUInteger)countOfCollectionItems {
    return [[self collectionItems] count];
}

- (TMCollectionItem *)objectInCollectionItemsAtIndex:(NSUInteger)idx {
    return [[self collectionItems] objectAtIndex:idx];
}

- (void)insertObject:(TMCollectionItem *)aTMCollectionItem inCollectionItemsAtIndex:(NSUInteger)idx {
    [[self collectionItems] insertObject:aTMCollectionItem atIndex:idx];
    aTMCollectionItem.sectionItem = self;
    [self.collectionViewBuilder addCellReuseIdentifierForRegistration:aTMCollectionItem.reuseIdentifier];
}

- (void)insertCollectionItems:(NSArray *)collectionItemArray atIndexes:(NSIndexSet *)indexes {
    [[self collectionItems] insertObjects:collectionItemArray atIndexes:indexes];
    [[self collectionItems] enumerateObjectsUsingBlock:^(TMCollectionItem *obj, NSUInteger idx, BOOL *stop) {
        obj.sectionItem = self;
        [self.collectionViewBuilder addCellReuseIdentifierForRegistration:obj.reuseIdentifier];
    }];
}

- (void)removeObjectFromCollectionItemsAtIndex:(NSUInteger)idx {
    [[self collectionItems] removeObjectAtIndex:idx];
}

- (void)removeCollectionItemsAtIndexes:(NSIndexSet *)indexes {
    [[self collectionItems] removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInCollectionItemsAtIndex:(NSUInteger)idx withObject:(TMCollectionItem *)aTMCollectionItem {
    [[self collectionItems] replaceObjectAtIndex:idx withObject:aTMCollectionItem];
    aTMCollectionItem.sectionItem = self;
    [self.collectionViewBuilder addCellReuseIdentifierForRegistration:aTMCollectionItem.reuseIdentifier];
}

- (void)replaceCollectionItemsAtIndexes:(NSIndexSet *)indexes withCollectionItems:(NSArray *)collectionItemArray {
    [[self collectionItems] replaceObjectsAtIndexes:indexes withObjects:collectionItemArray];
    [[self collectionItems] enumerateObjectsUsingBlock:^(TMCollectionItem *obj, NSUInteger idx, BOOL *stop) {
        obj.sectionItem = self;
        [self.collectionViewBuilder addCellReuseIdentifierForRegistration:obj.reuseIdentifier];
    }];
}

- (NSUInteger)indexOfCollectionItem:(TMCollectionItem *)item {
    return [[self collectionItems] indexOfObject:item];
}

@end
