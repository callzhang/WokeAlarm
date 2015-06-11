//
//  TMTableViewRowItemDataSource.h
//  Pods
//
//  Created by Zitao Xiong on 6/1/15.
//
//

#import <Foundation/Foundation.h>
#import "TMTableViewSectionItemDataSourceDelegate.h"

@class TMSectionItem;


@protocol TMTableViewSectionItemDataSource
@required
- (NSUInteger)countOfSectionItems;
- (TMSectionItem *)objectInSectionItemsAtIndex:(NSUInteger)idx;
- (NSUInteger)indexOfSectionItem:(TMSectionItem *)sectionItem;
- (void)removeAllSectionItems;
@property (nonatomic, weak) NSObject<TMTableViewSectionItemDataSourceDelegate> *delegate;

- (NSArray *)sectionIndexTitles;
- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;

@optional

- (NSArray *)setSectionIndexTitles:(NSArray *)sectionIndexTitles;
- (void)replaceSectionItemsAtIndexes:(NSIndexSet *)indexes withSectionItems:(NSArray *)sectionItemsArray;
- (void)replaceObjectInSectionItemsAtIndex:(NSUInteger)idx withObject:(TMSectionItem *)aTMSectionItem;
- (void)removeSectionItemsAtIndexes:(NSIndexSet *)indexes;
- (void)removeObjectFromSectionItemsAtIndex:(NSUInteger)idx;
- (void)insertSectionItems:(NSArray *)sectionItemsArray atIndexes:(NSIndexSet *)indexes;
- (void)insertObject:(TMSectionItem *)aSectionItem inSectionItemsAtIndex:(NSUInteger)idx;
- (void)removeFromSectionItems:(TMSectionItem *)sectionItemsObject;
- (void)addToSectionItems:(TMSectionItem *)sectionItemsObject;
@end

@interface TMTableViewArraySectionItemDataSource : NSObject<TMTableViewSectionItemDataSource>
@end
