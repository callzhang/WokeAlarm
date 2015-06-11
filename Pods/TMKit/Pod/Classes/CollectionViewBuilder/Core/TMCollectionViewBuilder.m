//
//  TMCollectionViewBuilder.m
//  Pods
//
//  Created by Zitao Xiong on 5/5/15.
//
//

#import "TMCollectionViewBuilder.h"
#import "TMCollectionViewDataSource.h"
#import "TMCollectionViewDelegate.h"
#import "TMCollectionSectionItem.h"
#import "TMCollectionItem.h"

@interface TMCollectionViewBuilder ()
@property (nonatomic, strong) NSMutableArray *mutableSectionItems;
@property (nonatomic, strong) TMCollectionViewDataSource *dataSource;
@property (nonatomic, strong) TMCollectionViewDelegate *delegate;

@property (nonatomic, strong) NSMutableSet *pendingRegisrationReuseIdentifiers;
@property (nonatomic, strong) NSMutableSet *didRegistratedReuseIdentifiers;

@end

@implementation TMCollectionViewBuilder

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView {
    self = [super init];
    if (self) {
        self.mutableSectionItems = [NSMutableArray array];
        self.pendingRegisrationReuseIdentifiers = [NSMutableSet set];
        self.didRegistratedReuseIdentifiers = [NSMutableSet set];
        self.delegate = [[TMCollectionViewDelegate alloc] initWithCollectionViewBuilder:self];
        self.dataSource = [[TMCollectionViewDataSource alloc] initWithCollectionViewBuilder:self];
        self.collectionView = collectionView;
    }
    return self;
}

- (void)setCollectionView:(UICollectionView *)collectionView {
    collectionView.delegate = self.delegate;
    collectionView.dataSource = self.dataSource;
    _collectionView = collectionView;
}

- (void)addCellReuseIdentifierForRegistration:(NSString *)reuseIdentifier {
    [self.pendingRegisrationReuseIdentifiers addObject:reuseIdentifier];
}

- (void)registerCellIfNecessary {
    if (self.pendingRegisrationReuseIdentifiers.count == 0) {
        return;
    }
    
    for (NSString *identifiers in self.pendingRegisrationReuseIdentifiers) {
        [self.collectionView registerNib:[UINib nibWithNibName:identifiers bundle:nil] forCellWithReuseIdentifier:identifiers];
    }
    
    [self.didRegistratedReuseIdentifiers addObjectsFromArray:[self.pendingRegisrationReuseIdentifiers allObjects]];
    [self.pendingRegisrationReuseIdentifiers removeAllObjects];
}

/**
 *  add all reuse identifer for registration later
 *
 */
- (void)addAllReuseIdentifersForColletionSectionItem:(TMCollectionSectionItem *)collectionSectionItem {
    for(NSUInteger i = 0; i < collectionSectionItem.countOfCollectionItems; i ++ ) {
        TMCollectionItem *item = [collectionSectionItem objectInCollectionItemsAtIndex:i];
        [self addCellReuseIdentifierForRegistration:item.reuseIdentifier];
    }
}

//mutableSectionItems
- (TMCollectionItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    TMCollectionSectionItem *section = [self objectInMutableSectionItemsAtIndex:indexPath.section];
    return [section objectInCollectionItemsAtIndex:indexPath.row];
}

- (void)addMutableSectionItem:(TMCollectionSectionItem *)aMutableSectionItem {
    [[self mutableSectionItems] addObject:aMutableSectionItem];
    aMutableSectionItem.collectionViewBuilder = self;
    [self addAllReuseIdentifersForColletionSectionItem:aMutableSectionItem];
}

- (void)removeMutableSectionItem:(TMCollectionSectionItem *)aMutableSectionItem {
    [[self mutableSectionItems] removeObject:aMutableSectionItem];
}

- (NSUInteger)countOfMutableSectionItems {
    return [[self mutableSectionItems] count];
}

- (TMCollectionSectionItem *)objectInMutableSectionItemsAtIndex:(NSUInteger)idx {
    return [[self mutableSectionItems] objectAtIndex:idx];
}

- (void)insertObject:(TMCollectionSectionItem *)aTMCollectionSectionItem inMutableSectionItemsAtIndex:(NSUInteger)idx {
    [[self mutableSectionItems] insertObject:aTMCollectionSectionItem atIndex:idx];
    aTMCollectionSectionItem.collectionViewBuilder = self;
    [self addAllReuseIdentifersForColletionSectionItem:aTMCollectionSectionItem];
}

- (void)insertMutableSectionItems:(NSArray *)mutableSectionItemArray atIndexes:(NSIndexSet *)indexes {
    [[self mutableSectionItems] insertObjects:mutableSectionItemArray atIndexes:indexes];
    [mutableSectionItemArray enumerateObjectsUsingBlock:^(TMCollectionSectionItem *item, NSUInteger idx, BOOL *stop) {
        item.collectionViewBuilder = self;
        [self addAllReuseIdentifersForColletionSectionItem:item];
    }];
}

- (void)removeObjectFromMutableSectionItemsAtIndex:(NSUInteger)idx {
    [[self mutableSectionItems] removeObjectAtIndex:idx];
}

- (void)removeMutableSectionItemsAtIndexes:(NSIndexSet *)indexes {
    [[self mutableSectionItems] removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInMutableSectionItemsAtIndex:(NSUInteger)idx withObject:(TMCollectionSectionItem *)aTMCollectionSectionItem {
    [[self mutableSectionItems] replaceObjectAtIndex:idx withObject:aTMCollectionSectionItem];
    aTMCollectionSectionItem.collectionViewBuilder = self;
    [self addAllReuseIdentifersForColletionSectionItem:aTMCollectionSectionItem];
}

- (void)replaceMutableSectionItemsAtIndexes:(NSIndexSet *)indexes withMutableSectionItems:(NSArray *)mutableSectionItemArray {
    [[self mutableSectionItems] replaceObjectsAtIndexes:indexes withObjects:mutableSectionItemArray];
    [mutableSectionItemArray enumerateObjectsUsingBlock:^(TMCollectionSectionItem *item, NSUInteger idx, BOOL *stop) {
        item.collectionViewBuilder = self;
        [self addAllReuseIdentifersForColletionSectionItem:item];
    }];
}

- (NSUInteger)indexOfCollectionSectionItem:(TMCollectionSectionItem *)item {
    return [[self mutableSectionItems] indexOfObject:item];
}

@end
