//
//  TMPickerViewTableViewCell.h
//  TMKit
//
//  Created by Zitao Xiong on 4/14/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMBaseTableViewCell.h"

@interface TMPickerViewTableViewCell : TMBaseTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *cellTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellDetailTextLabel;

@end
