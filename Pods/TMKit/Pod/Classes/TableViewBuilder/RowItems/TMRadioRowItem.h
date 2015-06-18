//
//  TMRadioRowItem.h
//  Pods
//
//  Created by Zitao Xiong on 5/4/15.
//
//

#import "TMRowItem.h"
#import "TMSimpleTableViewController.h"

@class TMRadioOptionRowItem, TMSimpleTableViewController, TMRadioRowItemSelectionModel;

@protocol TMRadioOptionRow
@property (nonatomic, strong) TMRadioRowItemSelectionModel *model;
@end

@interface TMRadioRowItemSelectionModel : NSObject
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) id context;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
- (instancetype)initWithText:(NSString *)text context:(id)context NS_DESIGNATED_INITIALIZER;
@end

@interface TMRadioRowItem : TMRowItem
@property (nonatomic, strong) NSArray *selectionModelList;
@property (nonatomic, strong) NSNumber *selectedIndex;
@property (nonatomic, readonly) NSString *selectedText;
@property (nonatomic, strong) NSString *textForNoSlection;

- (instancetype)initWithSelectionListWithText:(NSArray *)texts selectedIndex:(NSNumber *)index NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) void (^didChooseOptionHandler)(TMRadioRowItem *radioRowItem, TMRadioOptionRowItem *optionRowItem);
- (void)setDidChooseOptionHandler:(void (^)(TMRadioRowItem *radioRowItem, TMRadioOptionRowItem *optionRowItem))didChooseOptionHandler;

@property (nonatomic, copy) void (^viewDidLoadForOptionViewController)(UITableViewController<TMSimpleTableViewController> *tableViewController, TMRadioRowItem *radioRow);
@end

@protocol TMRadioRowTableViewCellProtocol <NSObject>
@property (unsafe_unretained, nonatomic) UILabel *cellTitleLabel;
@property (unsafe_unretained, nonatomic) UILabel *selectionTextLabel;
@end