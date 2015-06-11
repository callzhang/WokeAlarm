//
//  TMBaseTableViewCell.m
//  Pods
//
//  Created by Zitao Xiong on 5/1/15.
//
//

#import "TMBaseTableViewCell.h"
#import "TMSkin.h"

@interface TMBaseTableViewCell()
@property (nonatomic, strong) UIView *topSeparator;
@property (nonatomic, strong) UIView *bottomSeparator;
@end

@implementation TMBaseTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        static UIColor *defaultSeparatorColor = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            UITableView *tableView = [[UITableView alloc] init];
            defaultSeparatorColor = [tableView separatorColor];
        });
        if (! defaultSeparatorColor) {
            defaultSeparatorColor = [UIColor lightGrayColor];
        }
        
        _tmSeparatorColor = defaultSeparatorColor;
        _topSeparatorLeftInset = TMTableViewCellLeftMargin(self);
        _bottomSeparatorLeftInset = TMTableViewCellLeftMargin(self);
        
        _topSeparator = [UIView new];
        _bottomSeparator = [UIView new];
        
        [self init_TMTableViewCell];
        
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (self.topSeparatorLeftInset > 0) {
        self.topSeparatorLeftInset = TMStandardMarginForView(self);
    }
    if (self.bottomSeparatorLeftInset > 0) {
        self.bottomSeparatorLeftInset = TMStandardMarginForView(self);
    }
}

- (void)setShowBottomSeparator:(BOOL)showBottomSeparator {
    _showBottomSeparator = showBottomSeparator;
    [self setNeedsLayout];
}

- (void)setShowTopSeparator:(BOOL)showTopSeparator {
    _showTopSeparator = showTopSeparator;
    [self setNeedsLayout];
}

- (void)setBottomSeparatorLeftInset:(CGFloat)bottomSeparatorLeftInset {
    _bottomSeparatorLeftInset = bottomSeparatorLeftInset;
    [self setNeedsLayout];
}

- (void)setTopSeparatorLeftInset:(CGFloat)topSeparatorLeftInset {
    _topSeparatorLeftInset = topSeparatorLeftInset;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat cellWidth = self.bounds.size.width;
    CGFloat cellHeight = self.bounds.size.height;
    CGFloat separatorHeight = 1.0/[UIScreen mainScreen].scale;
    
    if (_showTopSeparator) {
        _topSeparator.backgroundColor = _tmSeparatorColor;
        _topSeparator.frame = CGRectMake(_topSeparatorLeftInset, 0.0, cellWidth, separatorHeight);
        [self addSubview:_topSeparator];
        
    } else {
        [_topSeparator removeFromSuperview];
    }
    
    if (_showBottomSeparator) {
        _bottomSeparator.backgroundColor = _tmSeparatorColor;
        _bottomSeparator.frame = CGRectMake(_bottomSeparatorLeftInset, cellHeight-separatorHeight, cellWidth, separatorHeight);
        [self addSubview:_bottomSeparator];
    } else {
        [_bottomSeparator removeFromSuperview];
    }
}

- (void)init_TMTableViewCell {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAppearance)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    
    [self updateAppearance];
}

- (void)updateAppearance {
//    self.textLabel.font = [TMSelectionTitleLabel defaultFont];
    [self invalidateIntrinsicContentSize];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
