//
//  TMBaseTableViewCell.h
//  Pods
//
//  Created by Zitao Xiong on 5/1/15.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface TMBaseTableViewCell : UITableViewCell
@property (nonatomic, copy, nullable) UIColor *tmSeparatorColor;
@property (nonatomic) BOOL showBottomSeparator;
@property (nonatomic) BOOL showTopSeparator;
@property (nonatomic) CGFloat topSeparatorLeftInset;
@property (nonatomic) CGFloat bottomSeparatorLeftInset;
@end
NS_ASSUME_NONNULL_END