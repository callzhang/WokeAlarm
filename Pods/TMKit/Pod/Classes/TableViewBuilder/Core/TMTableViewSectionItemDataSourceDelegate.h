//
//  TMTableViewRowItemDataSourceDelegate.h
//  Pods
//
//  Created by Zitao Xiong on 6/1/15.
//
//

#import <Foundation/Foundation.h>
@class TMTableViewFetchedResultsSectionItemDataSource, TMSectionItem;

@protocol TMTableViewSectionItemDataSourceDelegate
@optional
- (void)didInsertSectionItem:(TMSectionItem *)object;
/**
 *  remove all section item will not call didRemoveSectionItem
 *
 */
- (void)didRemoveSectionItem:(TMSectionItem *)object;
- (void)didFetchSectionItem:(TMSectionItem *)object;

- (void)fetchedResultsRowItemDataSource:(TMTableViewFetchedResultsSectionItemDataSource *)dataSrouce didCreatedFetchedResultsSectionItem:(TMSectionItem *)sectionItem;
@end
