//
//  TMLabelRowItem.h
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

#import "TMRowItem.h"
#import "TMKit.h"

@interface TMLabelRowItem : TMRowItem
@end

@interface TMSectionItem (LabelRowItem)
- (TMLabelRowItem *)addLabelRowItemWithText:(NSString *)text;
- (TMLabelRowItem *)addLabelRowItemWithText:(NSString *)text didSelectRowHandler:(void (^)(TMLabelRowItem *rowItem))handler;
@end