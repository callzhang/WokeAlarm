//
//  TMHelper.m
//  Pods
//
//  Created by Zitao Xiong on 5/12/15.
//
//

#import "TMHelper.h"
@import Foundation;
@import UIKit;

CGFloat TMExpectedLabelHeight(UILabel *label) {
    CGSize expectedLabelSize = [label.text boundingRectWithSize:CGSizeMake(label.frame.size.width, CGFLOAT_MAX)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{ NSFontAttributeName : label.font }
                                                        context:nil].size;
    return expectedLabelSize.height;
}

void TMAdjustHeightForLabel(UILabel *label) {
    CGRect rect = label.frame;
    rect.size.height = TMExpectedLabelHeight(label);
    label.frame = rect;
}

id TMDynamicCast_(id x, Class objClass) {
    return [x isKindOfClass:objClass] ? x : nil;
}

UIImage *TMImageWithColor(UIColor *color) {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

UIColor *TMRGBA(uint32_t x, CGFloat alpha) {
    CGFloat b = (x & 0xff) / 255.0f; x >>= 8;
    CGFloat g = (x & 0xff) / 255.0f; x >>= 8;
    CGFloat r = (x & 0xff) / 255.0f;
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

UIColor *TMRGB(uint32_t x) {
    return TMRGBA(x, 1.0f);
}