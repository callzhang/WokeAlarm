//
//  TMDatePickerTableViewCell.h
//  TMKit
//
//  Created by Zitao Xiong on 4/26/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMBaseTableViewCell.h"

@interface TMInlineDatePickerTableViewCell : TMBaseTableViewCell
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end
