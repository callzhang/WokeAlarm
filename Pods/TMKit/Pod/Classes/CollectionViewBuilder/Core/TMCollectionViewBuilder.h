//
//  TMCollectionViewBuilder.h
//  Pods
//
//  Created by Zitao Xiong on 5/5/15.
//
//

@import Foundation;
@import UIKit;
#import "TMCollectionSectionItem.h"

@class TMCollectionItem;
@interface TMCollectionViewBuilder : NSObject
@property (nonatomic, weak) UICollectionView *collectionView;

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;

- (void)addCellReuseIdentifierForRegistration:(NSString *)reuseIdentifier;
- (void)registerCellIfNecessary;
///////  mutableSectionItems  ///////
- (TMCollectionItem *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (void)addMutableSectionItem:(TMCollectionSectionItem *)aMutableSectionItem;
- (void)removeMutableSectionItem:(TMCollectionSectionItem *)aMutableSectionItem;
- (NSUInteger)countOfMutableSectionItems;
- (NSUInteger)indexOfCollectionSectionItem:(TMCollectionSectionItem *)item;

- (TMCollectionSectionItem *)objectInMutableSectionItemsAtIndex:(NSUInteger)idx;
- (void)insertObject:(TMCollectionSectionItem *)aTMCollectionSectionItem inMutableSectionItemsAtIndex:(NSUInteger)idx;
- (void)insertMutableSectionItems:(NSArray *)mutableSectionItemArray atIndexes:(NSIndexSet *)indexes;
- (void)removeObjectFromMutableSectionItemsAtIndex:(NSUInteger)idx;
- (void)removeMutableSectionItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMutableSectionItemsAtIndex:(NSUInteger)idx withObject:(TMCollectionSectionItem *)aTMCollectionSectionItem;
- (void)replaceMutableSectionItemsAtIndexes:(NSIndexSet *)indexes withMutableSectionItems:(NSArray *)mutableSectionItemArray;
@end
