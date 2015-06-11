//
//  TMShapeView.h
//  CustomView
//
//  Created by Zitao Xiong on 5/13/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMCustomView.h"

NS_ASSUME_NONNULL_BEGIN
IB_DESIGNABLE
@interface TMShapeView : TMCustomView
- (CAShapeLayer *)shapeLayer;


/**
 *  CAShapeLayerBacked
 */
@property(nullable) IBInspectable UIColor *fillColor;
@property(nullable) IBInspectable UIColor *strokeColor;
@property CGFloat IBInspectable strokeStart;
@property CGFloat IBInspectable strokeEnd;
@property CGFloat IBInspectable lineWidth;
@property(copy, nullable) IBInspectable NSString *lineCap;
@property(copy, nullable) IBInspectable NSString *lineJoin;
@property CGFloat IBInspectable lineDashPhase;
@property(copy, nullable) NSArray *lineDashPattern;
@property(nullable) CGPathRef path;
@property (nonatomic, strong, nullable) UIBezierPath *bezierPath;
@end
NS_ASSUME_NONNULL_END