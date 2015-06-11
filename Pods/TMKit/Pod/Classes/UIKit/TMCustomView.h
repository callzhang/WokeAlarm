//
//  TMCustomView.h
//  CustomView
//
//  Created by Zitao Xiong on 5/13/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TMShapeView;

IB_DESIGNABLE
@interface TMCustomView : UIView
@property(nonatomic, strong) IBInspectable TMShapeView *backgroundView;

@property(nonatomic, readwrite, nullable) IBInspectable UIColor *borderColor;
@property(nonatomic, readwrite) IBInspectable CGFloat borderWidth;
@property(nonatomic, readwrite) IBInspectable CGFloat cornerRadius;
@property(nonatomic, readwrite, nullable) IBInspectable UIColor *backgroundColor;
@property(nonatomic, readwrite) IBInspectable CGFloat shadowOpacity;
@property(nonatomic, readwrite) IBInspectable CGFloat shadowRadius;
@property(nonatomic, readwrite) IBInspectable CGSize shadowOFfset;
@property(nonatomic, readwrite, nullable) IBInspectable UIColor *shadowColor;
@end
NS_ASSUME_NONNULL_END