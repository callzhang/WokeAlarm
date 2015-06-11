//
//  TMTextFieldRowItem.m
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

#import "TMTextFieldRowItem.h"
#import "FBKVOController.h"
#import "FBKVOController+Binding.h"
#import "TMKit.h"
#import "TMTextFieldTableViewCell.h"

@interface TMTextFieldRowItem()
@end

@implementation TMTextFieldRowItem
#pragma mark -
+ (NSString *)reuseIdentifier {
   return @"TMTextFieldTableViewCell";
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.heightForRow = 44;
        self.hintSpacing = 10;
        self.minimumLeadingSpacing = 80;
    }
    return self;
}

- (UITableViewCell *)cellForRow {
    TMTextFieldTableViewCell *cell = (id) [super cellForRow];
    cell.inputTextField.placeholder = self.placeHolderText;
    cell.inputTextField.text = self.text;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextChanged:) name:UITextFieldTextDidChangeNotification object:cell.inputTextField];
    
    cell.cellTextLabel.text = self.hintText;
    
    if (self.hintText) {
        cell.spacingLayoutConstrant.constant = self.hintSpacing;
    }
    else {
        self.minimumLeadingSpacing = 0;
    }
    
    cell.textFieldLeadingMiniumSpacingConstraint.constant = self.minimumLeadingSpacing;
    
    return cell;
}

- (void)didEndDisplayingCell:(TMTextFieldTableViewCell *)cell {
    [super didEndDisplayingCell:cell];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:cell.inputTextField];
}

- (void)onTextChanged:(NSNotification *)noti {
    UITextField *textField = noti.object;
    self.text = textField.text;
    if (self.didTextChangedHandler) {
        self.didTextChangedHandler(self);
    }
}
@end

@implementation TMSectionItem (TextFiedRowItem)
- (TMTextFieldRowItem *)addTextFieldRowItemWithHintText:(NSString *)hintText placeHolder:(NSString *)placeHolder text:(NSString *)text observee:(id)object keyPath:(NSString *)keypath {
    TMTextFieldRowItem *rowItem = [self addTextFieldRowItemWithHintText:hintText placeHolder:placeHolder text:text textFieldTextDidChange:^(NSString *text) {
        [object setValue:text forKey:keypath];
    }];
    
    return rowItem;
}

- (TMTextFieldRowItem *)addTextFieldRowItemWithHintText:(NSString *)hintText placeHolder:(NSString *)placeHolder text:(NSString *)text textFieldTextDidChange:(void (^)(NSString *text))block{
    TMTextFieldRowItem *row = [TMTextFieldRowItem new];
    row.hintText = hintText;
    row.text = text;
    row.placeHolderText = placeHolder;
    [row bindKeypath:@keypath(row.text) withChangeBlock:^(id change) {
        if (block) {
            block(change);
        }
    }];
    
    [self addRowItem:row];
    return row;
}

@end