//
//  TMInlineDatePickerRowItem.h
//  TMKit
//
//  Created by Zitao Xiong on 4/26/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMRowItem.h"

@class TMDatePickerConfigurator;
@interface TMInlineDatePickerRowItem : TMRowItem
@property (nonatomic, copy) void (^didValueChangedHandler) (TMInlineDatePickerRowItem *item);
@property (nonatomic, weak) TMDatePickerConfigurator *configurator;
@end
