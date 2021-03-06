//
//  EWBackgroundView.m
//  Woke
//
//  Created by Lee on 6/7/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWBackgroundView.h"

@implementation EWBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //set background color
        UIImage *bg = [ImagesCatalog wokeBackground];
        UIImageView *bgView = [[UIImageView alloc] initWithImage:bg];
        bgView.frame = frame;
        bgView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:bgView];
    }
    return self;
}

@end
