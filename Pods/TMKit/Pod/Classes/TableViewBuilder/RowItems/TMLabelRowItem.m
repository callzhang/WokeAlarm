//
//  TMLabelRowItem.m
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

#import "TMLabelRowItem.h"
#import "TMTextLabelTableViewCell.h"
#import "FBKVOController+Binding.h"
#import "EXTScope.h"
#import "EXTKeyPathCoding.h"

@implementation TMLabelRowItem
+ (NSString *)reuseIdentifier {
    return NSStringFromClass([TMTextLabelTableViewCell class]);
}

- (UITableViewCell *)cellForRow {
    TMTextLabelTableViewCell *cell = (id) [super cellForRow];
    [self bindKeypath:@keypath(TMLabelRowItem.new, text) toLabel:cell.titleLabel];
    return cell;
}
@end

@implementation TMSectionItem (LabelRowItem)
- (TMLabelRowItem *)addLabelRowItemWithText:(NSString *)text {
    return [self addLabelRowItemWithText:text didSelectRowHandler:nil];
}

- (TMLabelRowItem *)addLabelRowItemWithText:(NSString *)text didSelectRowHandler:(void (^)(TMLabelRowItem *rowItem))handler {
    TMLabelRowItem *row = [TMLabelRowItem new];
    row.text = text;
    [self addRowItem:row];
    row.didSelectRowHandler = handler;
    return row;
}

@end