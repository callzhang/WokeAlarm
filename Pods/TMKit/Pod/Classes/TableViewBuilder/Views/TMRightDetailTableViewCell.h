//
//  TMRightDetailTableViewCell.h
//
//  Created by Zitao Xiong on 4/20/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMBaseTableViewCell.h"

@interface TMRightDetailTableViewCell : TMBaseTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *cellTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellDetailLabel;

@end
