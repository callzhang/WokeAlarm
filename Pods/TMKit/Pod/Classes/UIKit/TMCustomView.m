//
//  TMCustomView.m
//  CustomView
//
//  Created by Zitao Xiong on 5/13/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMCustomView.h"
#import "TMShapeView.h"
NS_ASSUME_NONNULL_BEGIN
@implementation TMCustomView
- (void)setBorderColor:(UIColor * __nullable)borderColor {
    self.layer.borderColor = borderColor.CGColor;
}

- (UIColor * __nullable)borderColor {
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth {
    return self.layer.borderWidth;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
    return self.layer.cornerRadius;
}

- (void)setBackgroundColor:(UIColor * __nullable)backgroundColor {
    self.layer.backgroundColor = backgroundColor.CGColor;
}

- (UIColor * __nullable)backgroundColor {
    return [UIColor colorWithCGColor:self.layer.backgroundColor];
}

- (CGFloat)shadowOpacity {
    return self.layer.shadowOpacity;
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity {
    self.layer.shadowOpacity = shadowOpacity;
}

- (CGFloat)shadowRadius {
    return self.layer.shadowRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius {
    self.layer.shadowRadius = shadowRadius;
}

- (CGSize)shadowOFfset {
    return self.layer.shadowOffset;
}

- (void)setShadowOFfset:(CGSize)shadowOFfset {
    self.layer.shadowOffset = shadowOFfset;
}

- (UIColor * __nullable)shadowColor {
    return [UIColor colorWithCGColor:self.layer.shadowColor];
}

- (void)setShadowColor:(UIColor * __nullable)shadowColor {
    self.layer.shadowColor = shadowColor.CGColor;
}

- (TMShapeView * __nonnull)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[TMShapeView alloc] initWithFrame:self.bounds];
        [self addSubview:_backgroundView];
    }
    
    return _backgroundView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundView.frame = self.bounds;
}
@end
NS_ASSUME_NONNULL_END
