//
//  UIImage+Extensions.h
//  HelpMeChoose
//
//  Created by Yifan Cai on 11/27/12.
//  Copyright (c) 2012 Nanaimo Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extensions)

- (UIImage *)imageAtRect:(CGRect)rect;
- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize;
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;
- (UIImage *)imageByScalingProportionallyToMaxSize:(CGSize)targetSize;
- (UIImage *)imageByScalingToSize:(CGSize)targetSize;
- (UIImage *)imageRotatedByRadians:(CGFloat)radians;
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
+ (UIImage *)imageWithColor:(UIColor *)color;


- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;
@end
