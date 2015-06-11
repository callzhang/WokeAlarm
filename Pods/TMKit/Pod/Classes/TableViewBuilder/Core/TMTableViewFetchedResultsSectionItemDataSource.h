//
//  TMTableViewFetchedResultsRowItemDataSource.h
//  Pods
//
//  Created by Zitao Xiong on 6/1/15.
//
//

#import <Foundation/Foundation.h>
#import "TMTableViewArraySectionItemDataSource.h"
@import CoreData;

/**
 *  TMTableViewFetchedResultsRowItemDataSource is a RowItem Datasource which managed by 
 * NSFetchedResultsController, the Section Item is created on the fly when needed.
 * SectionItem only support TMFetchedResultsSectionItem and it's subclass
 * comtomizaiton is done via TMTableViewRowItemDataSourceDelegate, which is a delegate of TMTableViewRowItemDataSource
 */
@interface TMTableViewFetchedResultsSectionItemDataSource : NSObject<TMTableViewSectionItemDataSource>
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
- (TMSectionItem *)insertedFetchedResultsSectionItemAtIndex:(NSUInteger)index;

// ---- TMTableViewRowItemDataSource -----
//@property (nonatomic, weak) NSObject<TMTableViewRowItemDataSourceDelegate> *delegate;
//- (NSUInteger)countOfSectionItems;
//- (TMSectionItem *)objectInSectionItemsAtIndex:(NSUInteger)idx;
//- (NSUInteger)indexOfSectionItem:(TMSectionItem *)sectionItem;
//- (void)removeAllSectionItems;
//- (NSArray *)sectionIndexTitles;
//- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;
@end
