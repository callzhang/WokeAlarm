//
//  TMInlinePickerTableViewCell.h
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMBaseTableViewCell.h"

@interface TMInlinePickerTableViewCell : TMBaseTableViewCell
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

@end
