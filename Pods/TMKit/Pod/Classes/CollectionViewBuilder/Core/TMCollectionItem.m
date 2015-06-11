//
//  TMCollectionItem.m
//  Pods
//
//  Created by Zitao Xiong on 5/5/15.
//
//

#import "TMCollectionItem.h"
#import "TMCollectionSectionItem.h"
#import "TMCollectionViewBuilder.h"
#import "TMKit.h"
#import "FBKVOController+Binding.h"

@interface TMCollectionItem ()

@end

@implementation TMCollectionItem
- (NSIndexPath *)indexPath {
    NSUInteger row = [self.sectionItem indexOfCollectionItem:self];
    NSUInteger section = self.sectionItem.section;
    if (row != NSNotFound && section != NSNotFound) {
        return [NSIndexPath indexPathForRow:row inSection:section];
    }
    
    return nil;
}

- (UICollectionView *)collectionView {
    return self.sectionItem.collectionViewBuilder.collectionView;
}

- (NSString *)reuseIdentifier {
    if (_reuseIdentifier) {
        return _reuseIdentifier;
    }
    return [self.class reuseIdentifier];
}

+ (NSString *)reuseIdentifier {
    return nil;
}
#pragma mark - Addition
- (void)setBackgroundViewColor:(UIColor *)backgroundViewColor {
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = backgroundViewColor;
}

- (UIColor *)backgroundViewColor {
    return self.backgroundView.backgroundColor;
}

- (void)setSelectedBackgroundViewColor:(UIColor *)selectedBackgroundViewColor {
    self.selectedBackgroundView = [UIView new];
    self.selectedBackgroundView.backgroundColor = selectedBackgroundViewColor;
}

- (UIColor *)selectedBackgroundViewColor {
    return self.selectedBackgroundView.backgroundColor;
}
#pragma mark - UICollectionViewDataSource
- (id)cellForItem {
    NSParameterAssert(self.reuseIdentifier);
    NSParameterAssert(self.indexPath);
    [self.sectionItem.collectionViewBuilder registerCellIfNecessary];
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:self.reuseIdentifier forIndexPath:self.indexPath];
    if (!cell) {
        [self.collectionView registerNib:[UINib nibWithNibName:self.reuseIdentifier bundle:nil] forCellWithReuseIdentifier:self.reuseIdentifier];
        cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:self.reuseIdentifier forIndexPath:self.indexPath];
        if (!cell) {
            DDLogError(@"deque cell with identifier:%@ failed", self.reuseIdentifier);
        }
    }
    
    if (self.backgroundView && self.backgroundView.superview != cell) {
        [self.backgroundView removeFromSuperview];
        cell.backgroundView = self.backgroundView;
    }
    
    
    if (self.selectedBackgroundView && self.selectedBackgroundView.superview != cell) {
        [self.selectedBackgroundView removeFromSuperview];
        cell.selectedBackgroundView = self.selectedBackgroundView;
    }
    
    cell.selected = self.selected;
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (BOOL)shouldHighlightItem {
    return YES;
}

- (void)didHighlightItem {
}

- (void)didUnhighlightItem {
}

- (BOOL)shouldSelectItem {
    return YES;
}

// called when the user taps on an already-selected item in multi-select mode
- (BOOL)shouldDeselectItem {
    return YES;
}

- (void)didSelectItem {
}

- (void)didDeselectItem {
}

- (void)willDisplayCell:(UICollectionViewCell *)cell NS_AVAILABLE_IOS(8_0) {
}

- (void)willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind NS_AVAILABLE_IOS(8_0) {
}

- (void)didEndDisplayingCell:(UICollectionViewCell *)cell {
    [self.KVOController unobserveAll];
    [cell.KVOController unobserveAll];
}

- (void)didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind  {
}

// These methods provide support for copy/paste actions on cells.
// All three should be implemented if any are.
- (BOOL)shouldShowMenu {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return YES;
}

- (void)performAction:(SEL)action withSender:(id)sender {
}

@end
