//
//  TMRowItem.h
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

#import "TMTableViewBuilderMacro.h"
#import "TMMacros.h"
NS_ASSUME_NONNULL_BEGIN

@import Foundation;
@import CoreData;
@import UIKit;

@class TMSectionItem, TMRowItem, TMSecondaryViewControllerOption;

@protocol TMRowItemProtocol <NSObject>
@required
+ (NSString *)reuseIdentifier;
@optional
//---------------- MAP to UITableViewDelegate ---------------
// Display customization
- (void)willDisplayCell:(UITableViewCell *)cell;
- (void)didEndDisplayingCell:(UITableViewCell *)cell;

// Variable height support
- (CGFloat)heightForRow;

// Use the estimatedHeight methods to quickly calcuate guessed values which will allow for fast load times of the table.
// If these methods are implemented, the above -tableView:heightForXXX calls will be deferred until views are ready to be displayed, so more expensive logic can be placed there.
- (CGFloat)estimatedHeightForRow NS_AVAILABLE_IOS(7_0);

// Accessories (disclosures).
- (void)accessoryButtonTappedForRow;
// Selection

// -tableView:shouldHighlightRowAtIndexPath: is called when a touch comes down on a row.
// Returning NO to that message halts the selection process and does not cause the currently selected row to lose its selected look while the touch is down.
- (BOOL)shouldHighlightRow NS_AVAILABLE_IOS(6_0);
- (void)didHighlightRow NS_AVAILABLE_IOS(6_0);
- (void)didUnhighlightRow NS_AVAILABLE_IOS(6_0);
// Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
- (NSIndexPath *)willSelectRow;
- (NSIndexPath *)willDeselectRow NS_AVAILABLE_IOS(3_0);
// Called after the user changes the selection.
- (void)didSelectRow;
- (void)didDeselectRow NS_AVAILABLE_IOS(3_0);

// Allows customization of the editingStyle for a particular cell located at 'indexPath'. If not implemented, all editable cells will have UITableViewCellEditingStyleDelete set for them when the table has editing property set to YES.
- (UITableViewCellEditingStyle)editingStyleForRow;
- (NSString *)titleForDeleteConfirmationButton NS_AVAILABLE_IOS(3_0);
- (NSArray *)editActionsForRow NS_AVAILABLE_IOS(8_0); // supercedes -tableView:titleForDeleteConfirmationButtonForRowAtIndexPath: if return value is non-nil

// Controls whether the background is indented while editing.  If not implemented, the default is YES.  This is unrelated to the indentation level below.  This method only applies to grouped style table views.
- (BOOL)shouldIndentWhileEditingRow;

// The willBegin/didEnd methods are called whenever the 'editing' property is automatically changed by the table (allowing insert/delete/move). This is done by a swipe activating a single row
- (void)willBeginEditingRow;
- (void)didEndEditingRow;

// Moving/reordering

// Allows customization of the target row for a particular row as it is being moved/reordered
- (NSIndexPath *)targetIndexPathForMoveFromRowToProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;

// Indentation
- (NSInteger)indentationLevelForRow; // return 'depth' of row for hierarchies

// Copy/Paste.  All three methods must be implemented by the delegate.

- (BOOL)shouldShowMenuForRow NS_AVAILABLE_IOS(5_0);
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender NS_AVAILABLE_IOS(5_0);
- (void)performAction:(SEL)action withSender:(id)sender NS_AVAILABLE_IOS(5_0);

//---------------- MAP to UITableViewDataSource ---------------
@required
- (UITableViewCell *)cellForRow;
@optional
// Editing

// Individual rows can opt out of having the -editing property set for them. If not implemented, all rows are assumed to be editable.
- (BOOL)canEditRow;

// Moving/reordering

// Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
- (BOOL)canMoveRow;
// Data manipulation - insert and delete support

// After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
// Not called for edit actions using UITableViewRowAction - the action's handler will be invoked instead
- (void)commitEditingStyle:(UITableViewCellEditingStyle)editingStyle;

// Data manipulation - reorder / moving support

- (void)moveRowToIndexPath:(NSIndexPath *)destinationIndexPath;
@end

typedef void (^DidSelectRowBlock)(id __nonnull rowItem);
typedef void (^DidDeselectRowBlock)(id __nonnull rowItem);



@interface TMRowItem : NSObject <TMRowItemProtocol, NSCopying>
@property (nonatomic, readonly, weak) TMSectionItem *sectionItem;
@property (nonatomic, readonly, copy, nullable) NSString *reuseIdentifier;
+ (NSString *)reuseIdentifier;

@property (nonatomic, readonly) NSIndexPath *indexPath;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (instancetype)init;
+ (instancetype)item;

@property (nonatomic, assign) BOOL clearsSelectionOnCellDidSelect;

@property (nonatomic, strong, nullable) id context;

@property (nonatomic, copy, nullable) void (^didSelectRowHandler)(id rowItem);
- (void)setDidSelectRowHandler:(void (^ __nullable)(id __nonnull rowItem))didSelectRowHandler;
@property (nonatomic, copy, nullable) void (^didDeselectRowHandler)(id rowItem);
- (void)setDidDeselectRowHandler:(void (^ __nullable)(id __nonnull rowItem))didDeselectRowHandler;
@property (nonatomic, copy, nullable) void (^willDisplayCellHandler) (id rowItem, id tableViewCell);
- (void)setWillDisplayCellHandler:(void (^)(id rowItem, id tableViewCell))willDisplayCellHandler;

- (void)selectRowAnimated:(BOOL)animated;
- (void)selectRowAnimated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition;
- (void)deselectRowAnimated:(BOOL)animated;
- (void)reloadRowWithAnimation:(UITableViewRowAnimation)animation;
- (void)deleteRowWithAnimation:(UITableViewRowAnimation)animation;

#pragma mark - Convenient Methods
- (UITableView *)tableView;

#pragma mark - UITableViewDataSoure
- (id)cellForRow;
@property (nonatomic, assign) BOOL canEditRow;
@property (nonatomic, assign) BOOL canMoveRow;
- (void)commitEditingStyle:(UITableViewCellEditingStyle)editingStyle;
- (void)moveRowToIndexPath:(NSIndexPath *)destinationIndexPath;

#pragma mark - UITableViewDelegate
- (void)willDisplayCell:(UITableViewCell *)cell TMP_REQUIRES_SUPER;
- (void)didEndDisplayingCell:(UITableViewCell *)cell TMP_REQUIRES_SUPER;
@property (nonatomic, assign) CGFloat heightForRow;
@property (nonatomic, assign) CGFloat estimatedHeightForRow;
- (void)accessoryButtonTappedForRow;
@property (nonatomic, assign) BOOL shouldHighlightRow;
- (void)didHighlightRow;
- (void)didUnhighlightRow;
- (NSIndexPath *)willSelectRow;
- (NSIndexPath *)willDeselectRow;
- (void)didSelectRow;
- (void)didDeselectRow;
@property (nonatomic, assign) UITableViewCellEditingStyle editingStyleForRow;
@property (nonatomic, strong) NSString *titleForDeleteConfirmationButton;
@property (nonatomic, readonly, nullable) NSArray *editActionsForRow;
@property (nonatomic, assign) BOOL shouldIndentWhileEditingRow;
- (void)willBeginEditingRow;
- (void)didEndEditingRow;
- (NSIndexPath *)targetIndexPathForMoveFromRowToProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath NS_UNAVAILABLE;
@property (nonatomic, assign) NSInteger indentationLevelForRow;
- (BOOL)shouldShowMenuForRow NS_AVAILABLE_IOS(5_0);
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender NS_AVAILABLE_IOS(5_0);
- (void)performAction:(SEL)action withSender:(id)sender NS_AVAILABLE_IOS(5_0);

#pragma mark - UITableViewCell
@property (nonatomic, strong, nullable) UIView *backgroundView;
@property (nonatomic, strong, nullable) UIColor *backgroundViewColor;
@property (nonatomic, strong, nullable) UIView *selectedBackgroundView;
@property (nonatomic, strong, nullable) UIColor *selectedBackgroundViewColor;
@property (nonatomic, strong, nullable) UIView *multipleSelectionBackgroundView;
@property (nonatomic, strong, nullable) UIColor *multipleSelectionBackgroundViewColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property(nonatomic, getter=isSelected) BOOL selected;

#pragma mark - Cell Property
@property (nonatomic, strong, nullable) NSString *text; // => cell.textLabel
@property (nonatomic, strong, nullable) NSString *detailText; //=> cell.detailTextLabel
@property (nonatomic, strong, nullable) UIImage *image; // => cell.imageView.image
@property (nonatomic, strong, nullable) UIImage *highlightedImage; // => cell.imageView.highlightedImage
@property (nonatomic, weak, nullable) UITableViewCell *cell;

#pragma mark - TMBaseTableViewCell
@property (nonatomic, copy, nullable) UIColor *tmSeparatorColor;
@property (nonatomic) BOOL showBottomSeparator;
@property (nonatomic) BOOL showTopSeparator;
@property (nonatomic) CGFloat topSeparatorLeftInset;
@property (nonatomic) CGFloat bottomSeparatorLeftInset;

#pragma mark - Secondary View Controller Hanlding
@property (nonatomic, strong, nullable) TMSecondaryViewControllerOption *secondaryViewControllerOption;
@property (nonatomic, weak, nullable) UIViewController *presentingViewController;

#pragma mark - Core Data

@property (nonatomic, strong, nullable) NSManagedObject *managedObject;
- (void)setManagedObject:(NSManagedObject * __nullable)managedObject TMP_REQUIRES_SUPER;
- (void)didManagedObjectUpdated:(NSManagedObject * __nullable)managedObject;
@property (nonatomic, copy, nullable) void (^didManagedObjctUpdatedBlock)(id rowItem, id managedObject);
- (void)setDidManagedObjctUpdatedBlock:(void (^)(id __nonnull rowItem, id __nonnull managedObject))didManagedObjctUpdatedBlock;
@end


@interface UITableViewCell (TMRowItem)
- (nullable id)rowItem;
/**
 *  retain reference
 *
 *  @param rowItem rowItem associated with cell
 */
- (void)setRowItem:(TMRowItem * __nullable) rowItem ;
@end

NS_ASSUME_NONNULL_END