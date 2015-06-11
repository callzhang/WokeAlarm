//
//  TMPickerRow.h
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMPickerComponent;
@interface TMPickerRow : NSObject
@property (nonatomic, strong) NSString *titleForRow;
@property (nonatomic, strong) NSAttributedString *attributedTitleForRow;
@property (nonatomic, strong) id context;

- (UIView *)viewForRowWithReusingView:(id)view;

@property (nonatomic, copy)UIView * (^viewForRowWithReusingViewHandler)(id reusingView);
- (void)setViewForRowWithReusingViewHandler:(UIView *(^)(id reusingView))viewForRowWithReusingViewHandler;

@property (nonatomic, weak, readonly) TMPickerComponent *component;
@property (nonatomic, copy) void (^didSelectPickerRowHandler) (TMPickerRow *row);
- (void)setDidSelectPickerRowHandler:(void (^)(TMPickerRow *pickerRow))didSelectPickerRowHandler;

- (void)didSelectRow;

- (NSInteger)row;
@end

