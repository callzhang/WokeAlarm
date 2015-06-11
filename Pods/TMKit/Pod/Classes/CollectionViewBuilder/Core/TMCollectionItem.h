//
//  TMCollectionItem.h
//  Pods
//
//  Created by Zitao Xiong on 5/5/15.
//
//

#import "TMMacros.h"
@import Foundation;
@import UIKit;
NS_ASSUME_NONNULL_BEGIN
@protocol TMCollectionSectionItemProtocol <NSObject>
#pragma mark - UICollectionViewDataSource
- (id)cellForItem;

#pragma mark - UICollectionViewDelegate

// Methods for notification of selection/deselection and highlight/unhighlight events.
// The sequence of calls leading to selection from a user touch is:
//
// (when the touch begins)
// 1. -collectionView:shouldHighlightItemAtIndexPath:
// 2. -collectionView:didHighlightItemAtIndexPath:
//
// (when the touch lifts)
// 3. -collectionView:shouldSelectItemAtIndexPath: or -collectionView:shouldDeselectItemAtIndexPath:
// 4. -collectionView:didSelectItemAtIndexPath: or -collectionView:didDeselectItemAtIndexPath:
// 5. -collectionView:didUnhighlightItemAtIndexPath:
- (BOOL)shouldHighlightItem;
- (void)didHighlightItem;
- (void)didUnhighlightItem;
- (BOOL)shouldSelectItem;
- (BOOL)shouldDeselectItem; // called when the user taps on an already-selected item in multi-select mode
- (void)didSelectItem;
- (void)didDeselectItem;

- (void)willDisplayCell:(UICollectionViewCell *)cell NS_AVAILABLE_IOS(8_0);
- (void)willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind  NS_AVAILABLE_IOS(8_0);
- (void)didEndDisplayingCell:(UICollectionViewCell *)cell;
- (void)didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind ;

// These methods provide support for copy/paste actions on cells.
// All three should be implemented if any are.
- (BOOL)shouldShowMenu;
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender;
- (void)performAction:(SEL)action withSender:(id)sender;
@end

@class TMCollectionSectionItem;
@interface TMCollectionItem : NSObject
@property (nonatomic, copy) NSString *reuseIdentifier;
+ (NSString *)reuseIdentifier;

@property (nonatomic, weak) TMCollectionSectionItem *sectionItem;
@property (nonatomic, readonly) NSIndexPath *indexPath;
@property (nonatomic, readonly) UICollectionView *collectionView;
#pragma mark - UICollectionViewDataSource
- (id)cellForItem;

#pragma mark - UICollectionViewDelegate

// Methods for notification of selection/deselection and highlight/unhighlight events.
// The sequence of calls leading to selection from a user touch is:
//
// (when the touch begins)
// 1. -collectionView:shouldHighlightItemAtIndexPath:
// 2. -collectionView:didHighlightItemAtIndexPath:
//
// (when the touch lifts)
// 3. -collectionView:shouldSelectItemAtIndexPath: or -collectionView:shouldDeselectItemAtIndexPath:
// 4. -collectionView:didSelectItemAtIndexPath: or -collectionView:didDeselectItemAtIndexPath:
// 5. -collectionView:didUnhighlightItemAtIndexPath:
- (BOOL)shouldHighlightItem;
- (void)didHighlightItem;
- (void)didUnhighlightItem;
- (BOOL)shouldSelectItem;
- (BOOL)shouldDeselectItem; // called when the user taps on an already-selected item in multi-select mode
- (void)didSelectItem;
- (void)didDeselectItem;

- (void)willDisplayCell:(UICollectionViewCell *)cell NS_AVAILABLE_IOS(8_0) TMP_REQUIRES_SUPER;
- (void)willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind  NS_AVAILABLE_IOS(8_0) TMP_REQUIRES_SUPER;
- (void)didEndDisplayingCell:(UICollectionViewCell *)cell TMP_REQUIRES_SUPER;
- (void)didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind TMP_REQUIRES_SUPER;

// These methods provide support for copy/paste actions on cells.
// All three should be implemented if any are.
- (BOOL)shouldShowMenu;
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender;
- (void)performAction:(SEL)action withSender:(id)sender;

#pragma mark - Properties
@property (nonatomic, strong, nullable) id context;
@property (nonatomic, strong, nullable) NSString *text; // => cell.textLabel
@property (nonatomic, strong, nullable) NSString *detailText; //=> cell.detailTextLabel
@property (nonatomic, strong, nullable) UIImage *image; // => cell.imageView.image
@property (nonatomic, strong, nullable) UIImage *highlightedImage; // => cell.imageView.highlightedImage
@property (nonatomic, strong, nullable) UIView *backgroundView;
@property (nonatomic, readwrite, nullable) UIColor *backgroundViewColor;
@property (nonatomic, strong, nullable) UIView *selectedBackgroundView;
@property (nonatomic, readwrite, nullable) UIColor *selectedBackgroundViewColor;
@property(nonatomic, getter=isSelected) BOOL selected;
@end
NS_ASSUME_NONNULL_END