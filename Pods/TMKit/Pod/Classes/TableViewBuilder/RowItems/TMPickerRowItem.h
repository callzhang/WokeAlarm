//
//  TMPickerRowItem.h
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMRowItem.h"
#import "TMInlinePickerRowItem.h"

@interface TMPickerRowItem : TMRowItem
@property (nonatomic, strong) TMInlinePickerRowItem *inlinePickerRow;

@property (nonatomic, assign, getter=isExpand) BOOL expand;

@property (nonatomic, copy) void (^didExpandChangeHandler) (TMPickerRowItem *rowItem, BOOL expand);
- (void)setDidExpandChangeHandler:(void (^)(TMPickerRowItem *rowItem, BOOL expand))didExpandChangeHandler;
@end
