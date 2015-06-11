//
//  TMDatePickerTableViewCell.h
//  TMKit
//
//  Created by Zitao Xiong on 4/26/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMBaseTableViewCell.h"

@interface TMDatePickerTableViewCell : TMBaseTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *cellTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelSpacingLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dateLabelToLeadingMinimumSpacingConstraint;
@end
