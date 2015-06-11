//
//  TMTextFieldTableViewCell.h
//
//  Created by Zitao Xiong on 4/21/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMBaseTableViewCell.h"

@interface TMTextFieldTableViewCell : TMBaseTableViewCell
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spacingLayoutConstrant;
@property (weak, nonatomic) IBOutlet UILabel *cellTextLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textFieldLeadingMiniumSpacingConstraint;
@end
