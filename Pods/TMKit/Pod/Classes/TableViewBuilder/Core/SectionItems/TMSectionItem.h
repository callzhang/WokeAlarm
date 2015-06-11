//
//  TMSectionItem.h
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

@import Foundation;
@import UIKit;
@import CoreData;

@protocol TMSectionItemProtocol <NSObject>
//---------------- MAP to UITableViewDelegate ---------------
@optional
- (void)willDisplayHeaderView:(UIView *)view NS_AVAILABLE_IOS(6_0);
- (void)willDisplayFooterView:(UIView *)view NS_AVAILABLE_IOS(6_0);
- (void)didEndDisplayingHeaderView:(UIView *)view NS_AVAILABLE_IOS(6_0);
- (void)didEndDisplayingFooterView:(UIView *)view NS_AVAILABLE_IOS(6_0);

- (CGFloat)heightForHeader;
- (CGFloat)heightForFooter;

- (CGFloat)estimatedHeightForHeader NS_AVAILABLE_IOS(7_0);
- (CGFloat)estimatedHeightForFooter NS_AVAILABLE_IOS(7_0);
- (UIView *)viewForHeader;   // custom view for header. will be adjusted to default or specified header height
- (UIView *)viewForFooter;   // custom view for footer. will be adjusted to default or specified footer height

//---------------- MAP to UITableViewDataSource ---------------
@required
- (NSInteger)numberOfRows;
@optional
- (NSString *)titleForHeader;    // fixed font style. use custom view (UILabel) if you want something different
- (NSString *)titleForFooter;
@end

@class TMTableViewBuilder, TMRowItem;

typedef NS_ENUM(NSUInteger, TMSectionItemType) {
    TMSectionItemTypeArray,
    TMSectionItemTypeFetchedResultsController,
};

@interface TMSectionItem : NSObject <TMSectionItemProtocol>
+ (instancetype)sectionItemWithType:(TMSectionItemType)type;
- (instancetype)initWithType:(TMSectionItemType)type NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) TMSectionItemType type;
@property (nonatomic, readonly, weak) TMTableViewBuilder *tableViewBuilder;
@property (nonatomic, readonly) NSInteger section;
- (void)removeFromTableView;
- (void)removeFromTableViewAnimated:(BOOL)animated;
#pragma mark - NSFetchedResultsController

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
- (CGFloat)estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (id<NSFetchedResultsSectionInfo>)sectionInfo;

#pragma mark - Section Property
- (NSInteger)numberOfRows;
@property (nonatomic, strong) NSString *titleForHeader;
@property (nonatomic, strong) NSString *titleForFooter;
//in order for heightForHeader to work, estimatedHeightForHeader must be set
@property (nonatomic, assign) CGFloat heightForHeader;
//in order for heightForFooter to work, estimatedHeightForFooter must be set
@property (nonatomic, assign) CGFloat heightForFooter;
@property (nonatomic, readwrite) CGFloat estimatedHeightForHeader;
@property (nonatomic, readwrite) CGFloat estimatedHeightForFooter;
@property (nonatomic, readwrite) id viewForHeader;
@property (nonatomic, readwrite) id viewForFooter;

//@property (nonatomic, readonly) NSArray *rowItems;
#pragma mark -
+ (NSString *)cellReuseIdentifierForHeader;
+ (NSString *)cellReuseIdentifierForFooter;

//if header or footer is a UITableViewHeaderFooterView, this will be called before return view from viewForFooter or viewForHeader
- (void)prepareForReuse:(UITableViewHeaderFooterView *)view NS_REQUIRES_SUPER;

#pragma mark - UITableViewDelegate
- (void)willDisplayHeaderView:(UIView *)view NS_AVAILABLE_IOS(6_0);
- (void)willDisplayFooterView:(UIView *)view NS_AVAILABLE_IOS(6_0);
- (void)didEndDisplayingHeaderView:(UIView *)view NS_AVAILABLE_IOS(6_0) NS_REQUIRES_SUPER;
- (void)didEndDisplayingFooterView:(UIView *)view NS_AVAILABLE_IOS(6_0) NS_REQUIRES_SUPER;

#pragma mark - Convenient Methods
- (UITableView *)tableView;

#pragma mark - Accessor
- (void)addRowItem:(TMRowItem *)rowItem;
- (TMRowItem *)rowItemAtIndex:(NSUInteger)index;
- (void)removeRowItemAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfRowItem:(TMRowItem *)rowItem;
#pragma mark - TMRowItem Accessor <KVO>
/**
 *  countOfRowItems always return the count of row items
 *  however numberOfRows is used for tableview, it can be subclass to return different numbers. 
 *  the detail usage see TMExpandableItem
 *  @return the count of row items
 */
- (NSUInteger)countOfRowItems;
- (id)objectInRowItemsAtIndex:(NSUInteger)idx;
- (void)insertObject:(TMRowItem *)anObject inRowItemsAtIndex:(NSUInteger)idx;
- (void)insertRowItems:(NSArray *)RowItemsArray atIndexes:(NSIndexSet *)indexes;
- (void)removeObjectFromRowItemsAtIndex:(NSUInteger)idx;
- (void)removeRowItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRowItemsAtIndex:(NSUInteger)idx withObject:(TMRowItem *)anObject;
- (void)replaceRowItemsAtIndexes:(NSIndexSet *)indexes withRowItems:(NSArray *)lowerRowItemsArray;

#pragma mark - Notify TableView
- (void)insertObject:(TMRowItem *)object inMutableRowItemsAtIndex:(NSUInteger)index withRowAnimation:(UITableViewRowAnimation)animation;
- (void)removeObjectFromMutableRowItemsAtIndex:(NSUInteger)index withRowAnimation:(UITableViewRowAnimation)animation;
//- (void)moveObject:(TMRowItem *)object inRowItemsAtIndex:(NSUInteger)index withRowAnimation:(UITableViewRowAnimation)animation;

#pragma mark - Cell

@property (nonatomic, strong) UIView *backgroundViewForHeader;
@property (nonatomic, readwrite) UIColor *backgroundColorForHeader;
@property (nonatomic, strong) UIView *backgroundViewForFooter;
@property (nonatomic, readwrite) UIColor *backgroundColorForFooter;

#pragma mark - Collection Methods

- (void)tm_each:(void (^)(id rowItem))block;

#pragma mark - Predicate
- (NSArray *)filterRowItemsUsingPredicate:(NSPredicate *)predicate;

#pragma mark - Indexed Subscript
- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(TMRowItem *)obj atIndexedSubscript:(NSUInteger)index;
@end