//
//  TMRadioTableViewCell.h
//  Pods
//
//  Created by Zitao Xiong on 5/4/15.
//
//

#import <UIKit/UIKit.h>
#import "TMBaseTableViewCell.h"
#import "TMRadioRowItem.h"

@interface TMRadioTableViewCell : TMBaseTableViewCell<TMRadioRowTableViewCellProtocol>
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *cellTitleLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *selectionTextLabel;

@end
