//
//  TMExpandableHeaderFooterView.h
//  Pods
//
//  Created by Zitao Xiong on 5/7/15.
//
//

#import <UIKit/UIKit.h>

@interface TMExpandableHeaderFooterView : UITableViewHeaderFooterView
@property (nonatomic, assign, getter=isExpand) BOOL expand;
@property (unsafe_unretained, nonatomic) UIButton *expandButton;
@end
