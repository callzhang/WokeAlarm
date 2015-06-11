//
//  TMShapeView.m
//  CustomView
//
//  Created by Zitao Xiong on 5/13/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMShapeView.h"
NS_ASSUME_NONNULL_BEGIN
@implementation TMShapeView
+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (CAShapeLayer *)shapeLayer {
    return (CAShapeLayer *)self.layer;
}



- (UIColor * __nullable)fillColor {
    return [UIColor colorWithCGColor:self.shapeLayer.fillColor];
}

- (void)setFillColor:(UIColor * __nullable)fillColor {
    self.shapeLayer.fillColor = fillColor.CGColor;
}

- (UIColor * __nullable)strokeColor {
    return [UIColor colorWithCGColor:self.shapeLayer.strokeColor];
}

- (void)setStrokeColor:(UIColor * __nullable)strokeColor {
    self.shapeLayer.strokeColor = strokeColor.CGColor;
}

- (CGFloat)strokeStart {
    return self.shapeLayer.strokeStart;
}

- (void)setStrokeStart:(CGFloat)strokeStart {
    self.shapeLayer.strokeStart = strokeStart;
}

- (CGFloat)strokeEnd {
    return self.shapeLayer.strokeEnd;
}

- (void)setStrokeEnd:(CGFloat)strokeEnd {
    self.shapeLayer.strokeEnd = strokeEnd;
}

- (CGFloat)lineWidth {
    return self.shapeLayer.lineWidth;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    self.shapeLayer.lineWidth = lineWidth;
}

- (void)setLineCap:(NSString * __nullable)lineCap {
    self.shapeLayer.lineCap = lineCap;
}

- (NSString * __nullable)lineCap {
    return self.shapeLayer.lineCap;
}

- (NSString * __nullable)lineJoin {
    return self.shapeLayer.lineJoin;
}

- (void)setLineJoin:(NSString * __nullable)lineJoin {
    self.shapeLayer.lineJoin = lineJoin;
}

- (CGFloat)lineDashPhase {
    return self.shapeLayer.lineDashPhase;
}

- (void)setLineDashPhase:(CGFloat)lineDashPhase {
    self.shapeLayer.lineDashPhase = lineDashPhase;
}

- (NSArray * __nullable)lineDashPattern {
    return self.shapeLayer.lineDashPattern;
}

- (void)setLineDashPattern:(NSArray * __nullable)lineDashPattern {
    self.shapeLayer.lineDashPattern = lineDashPattern;
}

- (void)setPath:(CGPathRef __nullable)path {
    self.shapeLayer.path = path;
}

- (CGPathRef __nullable)path {
    return self.shapeLayer.path;
}

- (void)setBezierPath:(UIBezierPath * __nullable)bezierPath {
    _bezierPath = bezierPath;
    self.shapeLayer.path = bezierPath.CGPath;
}

@end
NS_ASSUME_NONNULL_END