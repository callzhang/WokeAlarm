//
//  TMStepperTableViewCell.h
//  Pods
//
//  Created by Zitao Xiong on 5/8/15.
//
//

#import <UIKit/UIKit.h>
#import "TMBaseTableViewCell.h"

@interface TMStepperTableViewCell : TMBaseTableViewCell
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *cellTextLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIStepper *cellStepper;
@end
