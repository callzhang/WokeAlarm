//
//  TMPickerDataSource.h
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMPickerBuilder;
@interface TMPickerDataSource : NSObject<UIPickerViewDataSource>

@property (nonatomic, weak, readonly) TMPickerBuilder *pickerBuilder;
- (instancetype)initWithPickerBuilder:(TMPickerBuilder *)builder;
@end
