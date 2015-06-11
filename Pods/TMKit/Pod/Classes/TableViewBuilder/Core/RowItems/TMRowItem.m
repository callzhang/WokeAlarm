//
//  TMRowItem.m
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

#import "TMRowItem.h"
#import "TMRowItem+Protected.h"
#import "TMTableViewBuilder.h"
#import "FBKVOController.h"
#import "FBKVOController+Binding.h"
#import "UITableView+RegisterRowItem.h"
#import "objc/runtime.h"
#import "TMKit.h"
#import "TMSecondaryViewControllerOption.h"

@interface TMRowItem ()
@property (nonatomic, copy) NSString *reuseIdentifier;

#pragma mark - protected
@property (nonatomic, weak) TMSectionItem *sectionItem;
@end

@implementation TMRowItem
- (instancetype)init {
    self = [super init];
    if (self) {
        [self __setup];
    }
    return self;
}
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super init];
    if (self) {
        self.reuseIdentifier = reuseIdentifier;
        [self __setup];
    }
    return self;
}

- (void)__setup {
    self.clearsSelectionOnCellDidSelect = YES;
    self.heightForRow = 50;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.editingStyleForRow = UITableViewRowAnimationNone;
    self.estimatedHeightForRow = UITableViewAutomaticDimension;
    self.shouldHighlightRow = YES;
}

+ (instancetype)item {
    if (![[self class] reuseIdentifier]) {
        return nil;
    }
    
    TMRowItem *item = [[[self class] alloc] initWithReuseIdentifier:[[self class] reuseIdentifier]];
    return item;
}

- (NSString *)reuseIdentifier {
    if (_reuseIdentifier) {
        return [_reuseIdentifier copy];
    }
    return [[self class] reuseIdentifier];
}

- (NSIndexPath *)indexPath {
    TMSectionItem *sectionItem = self.sectionItem;
    NSUInteger row = [sectionItem indexOfRowItem:self];
    if (row != NSNotFound && sectionItem.section != NSNotFound) {
        return [NSIndexPath indexPathForRow:row inSection:sectionItem.section];
    }
    
    return nil;
}
#pragma mark - UITableViewDataSource
- (id)cellForRow {
    UITableView *tableView = self.tableView;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.reuseIdentifier];
    if (!cell) {
        [tableView registerRowItem:self];
        cell = [tableView dequeueReusableCellWithIdentifier:self.reuseIdentifier];
        if (!cell) {
            DDLogError(@"cell is nil");
        }
    }
    
    cell.selectionStyle = self.selectionStyle;
    if (self.backgroundView && self.backgroundView.superview != cell) {
        [self.backgroundView removeFromSuperview];
        cell.backgroundView = self.backgroundView;
    }
    
    
    if (self.selectedBackgroundView && self.selectedBackgroundView.superview != cell) {
        [self.selectedBackgroundView removeFromSuperview];
        cell.selectedBackgroundView = self.selectedBackgroundView;
    }
    
    if (self.multipleSelectionBackgroundView && self.multipleSelectionBackgroundView.superview != cell) {
        [self.multipleSelectionBackgroundView removeFromSuperview];
        cell.multipleSelectionBackgroundView = self.multipleSelectionBackgroundView;
    }
    
    cell.selected = self.selected;
    
    [cell unbind];
    [self unbind];
    cell.rowItem = self;
    self.cell = cell;
    
    return cell;
}

- (void)commitEditingStyle:(UITableViewCellEditingStyle)editingStyle {
    
}

- (void)moveRowToIndexPath:(NSIndexPath *)destinationIndexPath {
    
}
#pragma mark - UITableViewDelegate
- (void)willDisplayCell:(UITableViewCell *)cell TMP_REQUIRES_SUPER {
    if (self.willDisplayCellHandler) {
        self.willDisplayCellHandler(self, cell);
    }
}

- (void)didEndDisplayingCell:(UITableViewCell *)cell TMP_REQUIRES_SUPER {
    [self unbind];
    [cell unbind];
    cell.rowItem = nil;
}

- (void)accessoryButtonTappedForRow {
    
}

- (void)didHighlightRow {
    
}

- (void)didUnhighlightRow {
    
}

- (NSIndexPath *)willSelectRow {
    return self.indexPath;
}

- (NSIndexPath *)willDeselectRow {
    return self.indexPath;
}

- (void)didSelectRow {
    if (self.clearsSelectionOnCellDidSelect) {
        [self deselectRowAnimated:YES];
    }
    
    if (self.didSelectRowHandler) {
        self.didSelectRowHandler(self);
    }
    
    if (self.secondaryViewControllerOption) {
        Class SimpleTableViewControllerClass = [self.sectionItem.tableViewBuilder classForType:TMTableViewBuilderClassTypeSimpleTableViewController];
        UIViewController<TMSimpleTableViewController> *simpleTableViewController = [[SimpleTableViewControllerClass alloc] init];
        @weakify(self);
        
        [simpleTableViewController setViewDidLoadCompletionHandler:^(UITableViewController<TMSimpleTableViewController> *vc) {
            @strongify(self);
            if (self.secondaryViewControllerOption.secondaryViewControllerViewDidLoadHandler) {
                self.secondaryViewControllerOption.secondaryViewControllerViewDidLoadHandler(vc, self);
            }
        }];
        [simpleTableViewController setViewWillDisappearCompletionHandler:^(UITableViewController<TMSimpleTableViewController> *vc, TMSimpleViewControllerResultType resultType) {
            @strongify(self);
            if (self.secondaryViewControllerOption.secondaryViewControllerViewWillDisappearHandler) {
                self.secondaryViewControllerOption.secondaryViewControllerViewWillDisappearHandler(vc, self, resultType);
            }
        }];
        
        if (self.secondaryViewControllerOption.presentationStyle == TMSecondaryViewControllerPresentationStyleShow) {
            [self.presentingViewController showViewController:simpleTableViewController sender:self];
        }
        else if (self.secondaryViewControllerOption.presentationStyle == TMSecondaryViewControllerPresentationStylePush) {
            [self.presentingViewController.navigationController pushViewController:simpleTableViewController animated:YES];
        }
        else if (self.secondaryViewControllerOption.presentationStyle == TMSecondaryViewControllerPresentationStylePresent) {
            [self.presentingViewController presentViewController:simpleTableViewController animated:YES completion:nil];
        }
    }
}

- (void)didDeselectRow {
    if (self.didDeselectRowHandler) {
        self.didDeselectRowHandler(self);
    }
}

- (void)willBeginEditingRow {
    
}

- (void)didEndEditingRow {
    
}

- (NSIndexPath *)targetIndexPathForMoveFromRowToProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    return proposedDestinationIndexPath;
}

- (BOOL)shouldShowMenuForRow NS_AVAILABLE_IOS(5_0) {
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender NS_AVAILABLE_IOS(5_0) {
    return NO;
}

- (void)performAction:(SEL)action withSender:(id)sender NS_AVAILABLE_IOS(5_0) {
    
}

- (NSArray * __nullable)editActionsForRow {
    return nil;
}

#pragma mark - UITableViewCell
- (UIView *)backgroundView {
    if (!_backgroundView && _backgroundViewColor) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = _backgroundViewColor;
        return view;
    }
    
    return _backgroundView;
}

- (UIView *)selectedBackgroundView {
    if (!_selectedBackgroundView && _selectedBackgroundViewColor) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = _selectedBackgroundViewColor;
        return view;
    }
    
    return _selectedBackgroundView;
}

- (UIView *)multipleSelectionBackgroundView {
    if (!_multipleSelectionBackgroundView && _multipleSelectionBackgroundViewColor) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = _multipleSelectionBackgroundViewColor;
        return view;
    }
    
    return _multipleSelectionBackgroundView;
}

#pragma mark Manipulating table view row
- (void)selectRowAnimated:(BOOL)animated {
    [self selectRowAnimated:animated scrollPosition:UITableViewScrollPositionNone];
}

- (void)selectRowAnimated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition {
    [self.sectionItem.tableViewBuilder.tableView selectRowAtIndexPath:self.indexPath animated:animated scrollPosition:scrollPosition];
}

- (void)deselectRowAnimated:(BOOL)animated {
    [self.sectionItem.tableViewBuilder.tableView deselectRowAtIndexPath:self.indexPath animated:animated];
}

- (void)reloadRowWithAnimation:(UITableViewRowAnimation)animation {
    [self.sectionItem.tableViewBuilder.tableView reloadRowsAtIndexPaths:@[self.indexPath] withRowAnimation:animation];
}

- (void)deleteRowWithAnimation:(UITableViewRowAnimation)animation {
    NSIndexPath *indexPath = [self.indexPath copy];
    [self.sectionItem removeRowItemAtIndex:indexPath.row];
    [self.sectionItem.tableViewBuilder.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:animation];
    
}
#pragma mark - Subclassing
+ (NSString *)reuseIdentifier {
    return nil;
}

#pragma mark - Convenient Methods
- (UITableView *)tableView {
    return self.sectionItem.tableView;
}

#pragma mark - Core Data 
- (void)setManagedObject:(NSManagedObject * __nullable)managedObject {
    _managedObject = managedObject;
    [self didManagedObjectUpdated:managedObject];
}

- (void)didManagedObjectUpdated:(NSManagedObject * __nullable)managedObject {
    if (self.didManagedObjctUpdatedBlock) {
        self.didManagedObjctUpdatedBlock(self, managedObject);
    }
}

#pragma mark - copy
- (id)copyWithZone:(NSZone *)zone
{
    TMRowItem *theCopy = [[[self class] allocWithZone:zone] init];  // use designated initializer
    
//    [theCopy setSectionItem:[self.sectionItem copy]];  //section should not be copied
    [theCopy setReuseIdentifier:[self.reuseIdentifier copy]];
//    [theCopy setIndexPath:[self.indexPath copy]];
    [theCopy setClearsSelectionOnCellDidSelect:self.clearsSelectionOnCellDidSelect];
    if ([self.context conformsToProtocol:@protocol(NSCopying)]) {
        [theCopy setContext:[self.context copy]];  //context should not be copied
    }
    else {
        [theCopy setContext:self.context];
    }
    
    //copy through property
    [theCopy setDidSelectRowHandler:self.didSelectRowHandler];
    [theCopy setDidDeselectRowHandler:self.didDeselectRowHandler];
    [theCopy setWillDisplayCellHandler:self.willDisplayCellHandler];
    [theCopy setCanEditRow:self.canEditRow];
    [theCopy setCanMoveRow:self.canMoveRow];
    [theCopy setHeightForRow:self.heightForRow];
    [theCopy setEstimatedHeightForRow:self.estimatedHeightForRow];
    [theCopy setShouldHighlightRow:self.shouldHighlightRow];
    [theCopy setEditingStyleForRow:self.editingStyleForRow];
    [theCopy setTitleForDeleteConfirmationButton:[self.titleForDeleteConfirmationButton copy]];
//    [theCopy setEditActionsForRow:[self.editActionsForRow copy]]; //to test
    [theCopy setShouldIndentWhileEditingRow:self.shouldIndentWhileEditingRow];
    [theCopy setIndentationLevelForRow:self.indentationLevelForRow];
    
    //should view be copied?
    [theCopy setBackgroundView:[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.backgroundView]]];
    [theCopy setSelectedBackgroundView:[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.selectedBackgroundView]]];
    [theCopy setMultipleSelectionBackgroundView:[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.multipleSelectionBackgroundView]]];
    
    [theCopy setBackgroundViewColor:[self.backgroundViewColor copy]];
    [theCopy setSelectedBackgroundViewColor:[self.selectedBackgroundViewColor copy]];
    [theCopy setMultipleSelectionBackgroundViewColor:[self.multipleSelectionBackgroundViewColor copy]];
    [theCopy setSelectionStyle:self.selectionStyle];
    [theCopy setSelected:self.selected];
    [theCopy setText:[self.text copy]];
    [theCopy setDetailText:[self.detailText copy]];
    //image should not be copied?
    [theCopy setImage:self.image];
    [theCopy setHighlightedImage:self.highlightedImage];
//    [theCopy setCell:[self.cell copy]]; //cell should not be copied
    [theCopy setTmSeparatorColor:[self.tmSeparatorColor copy]];
    [theCopy setShowBottomSeparator:self.showBottomSeparator];
    [theCopy setShowTopSeparator:self.showTopSeparator];
    [theCopy setTopSeparatorLeftInset:self.topSeparatorLeftInset];
    [theCopy setBottomSeparatorLeftInset:self.bottomSeparatorLeftInset];
    [theCopy setSecondaryViewControllerOption:[self.secondaryViewControllerOption copy]];
    
    //presentingViewController is not copied
    [theCopy setPresentingViewController:self.presentingViewController];
    //no need to copy managed object
    [theCopy setManagedObject:self.managedObject];
    //copied through property attribute.
    [theCopy setDidManagedObjctUpdatedBlock:self.didManagedObjctUpdatedBlock];
    
    return theCopy;
}
@end

@implementation UITableViewCell (TMRowItem)

- (id)rowItem {
    return objc_getAssociatedObject(self, @selector(rowItem));
}

- (void)setRowItem:(TMRowItem *)rowItem {
    objc_setAssociatedObject(self, @selector(rowItem), rowItem, OBJC_ASSOCIATION_RETAIN);
}

@end