//
//  UIView+Mask.m
//  Woke
//
//  Created by Zitao Xiong on 25/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "UIView+Mask.h"
#import "NSObject+BKAssociatedObjects.h"


@implementation UIView(Mask)
const char *kHexEdgeKey;
+ (UIBezierPath *)getHexagonSoftPath{
    
    UIBezierPath* polygonPath = [UIBezierPath bezierPath];
    [polygonPath moveToPoint: CGPointMake(72.5, 17.5)];
    [polygonPath addCurveToPoint: CGPointMake(42.87, 0.93) controlPoint1: CGPointMake(65.28, 13.42) controlPoint2: CGPointMake(47.9, 3.76)];
    [polygonPath addCurveToPoint: CGPointMake(36.84, 0.93) controlPoint1: CGPointMake(41, -0.12) controlPoint2: CGPointMake(38.37, 0.06)];
    [polygonPath addCurveToPoint: CGPointMake(8.07, 17.62) controlPoint1: CGPointMake(35.71, 1.57) controlPoint2: CGPointMake(13.74, 14.31)];
    [polygonPath addCurveToPoint: CGPointMake(5, 22.5) controlPoint1: CGPointMake(6.05, 18.81) controlPoint2: CGPointMake(4.99, 20.08)];
    [polygonPath addCurveToPoint: CGPointMake(5, 57) controlPoint1: CGPointMake(5.02, 29.07) controlPoint2: CGPointMake(4.99, 55.25)];
    [polygonPath addCurveToPoint: CGPointMake(7.5, 61.5) controlPoint1: CGPointMake(5.01, 58.75) controlPoint2: CGPointMake(5.97, 60.61)];
    [polygonPath addCurveToPoint: CGPointMake(37.47, 78.89) controlPoint1: CGPointMake(9.03, 62.39) controlPoint2: CGPointMake(35.79, 77.96)];
    [polygonPath addCurveToPoint: CGPointMake(42.87, 78.89) controlPoint1: CGPointMake(39.15, 79.82) controlPoint2: CGPointMake(40.63, 80.28)];
    [polygonPath addCurveToPoint: CGPointMake(73.01, 61.05) controlPoint1: CGPointMake(49.13, 75.01) controlPoint2: CGPointMake(71.62, 61.94)];
    [polygonPath addCurveToPoint: CGPointMake(74.99, 56.45) controlPoint1: CGPointMake(74.9, 59.83) controlPoint2: CGPointMake(75, 58.3)];
    [polygonPath addCurveToPoint: CGPointMake(74.99, 22.64) controlPoint1: CGPointMake(74.97, 52.25) controlPoint2: CGPointMake(74.93, 29.58)];
    [polygonPath addCurveToPoint: CGPointMake(72.5, 17.5) controlPoint1: CGPointMake(75.01, 20.14) controlPoint2: CGPointMake(74.31, 18.52)];
    [polygonPath closePath];
    polygonPath.miterLimit = 11;
    polygonPath.lineJoinStyle = kCGLineJoinRound;
    
    
    return polygonPath;
}

- (void)applyHexagonSoftMask {
    NSNumber *applied = [self bk_associatedValueForKey:&kHexEdgeKey];
    if (applied.boolValue) {
        return;
    }
    
    CAShapeLayer *hexagonMask = [[CAShapeLayer alloc] initWithLayer:self.layer];
    UIBezierPath *hexagonPath = [self.class getHexagonSoftPath];
    
    float originalSize = 80.0;
    //scale
    float height = self.bounds.size.height;
    float width = self.bounds.size.width;
    float ratioWidth = width / originalSize;
    float ratioHeight = height / originalSize;
    [hexagonPath applyTransform:CGAffineTransformMakeScale(ratioWidth, ratioHeight)];
    
    //apply mask
    hexagonMask.path = hexagonPath.CGPath;
    self.layer.mask  = hexagonMask;
    self.layer.masksToBounds = YES;
    //view.clipsToBounds = YES;
    
    [self bk_atomicallyAssociateValue:@(YES) withKey:&kHexEdgeKey];
    
    //stroke
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, self.window.screen.scale);
    [[UIColor colorWithWhite:1 alpha:0.8] setStroke];
    hexagonPath.lineWidth = 1;
    [hexagonPath stroke];
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *hexEdge = [[UIImageView alloc] initWithImage:img];
    [self addSubview:hexEdge];
}
@end
