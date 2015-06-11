//
//  TMCollectionSectionItem.h
//  Pods
//
//  Created by Zitao Xiong on 5/5/15.
//
//

#import <Foundation/Foundation.h>

@class TMCollectionItem, TMCollectionViewBuilder;
@interface TMCollectionSectionItem : NSObject
@property (nonatomic, readonly) NSUInteger section;
@property (nonatomic, weak) TMCollectionViewBuilder *collectionViewBuilder;

///////  collectionItems  ///////
- (void)addCollectionItem:(TMCollectionItem *)aCollectionItem;
- (void)removeCollectionItem:(TMCollectionItem *)aCollectionItem;
- (NSUInteger)countOfCollectionItems;
- (TMCollectionItem *)objectInCollectionItemsAtIndex:(NSUInteger)idx;
- (void)insertObject:(TMCollectionItem *)aTMCollectionItem inCollectionItemsAtIndex:(NSUInteger)idx;
- (void)insertCollectionItems:(NSArray *)collectionItemArray atIndexes:(NSIndexSet *)indexes;
- (void)removeObjectFromCollectionItemsAtIndex:(NSUInteger)idx;
- (void)removeCollectionItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCollectionItemsAtIndex:(NSUInteger)idx withObject:(TMCollectionItem *)aTMCollectionItem;
- (void)replaceCollectionItemsAtIndexes:(NSIndexSet *)indexes withCollectionItems:(NSArray *)collectionItemArray;
- (NSUInteger)indexOfCollectionItem:(TMCollectionItem *)item;
@end
