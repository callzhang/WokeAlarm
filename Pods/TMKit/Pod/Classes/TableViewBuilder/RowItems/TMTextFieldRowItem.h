//
//  TMTextFieldRowItem.h
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

#import "TMRowItem.h"
#import "TMSectionItem.h"

@interface TMTextFieldRowItem : TMRowItem
@property (nonatomic, strong) NSString *placeHolderText;

@property (nonatomic, strong) NSString *hintText;
@property (nonatomic, assign) NSInteger hintSpacing;
@property (nonatomic, assign) NSInteger minimumLeadingSpacing;
@property (nonatomic, copy) void (^didTextChangedHandler) (TMTextFieldRowItem *rowItem);
-(void)setDidTextChangedHandler:(void (^)(TMTextFieldRowItem *rowItem))didTextChangedHandler;
@end

@interface TMSectionItem (TextFieldRowItem)
/**
 *  convenient method for adding TextVieRowItem
 *
 *  @param hintText hintText
 *  @param text     text
 *  @param object   observee object which be notified when change happens
 *  @param keypath  keypath to set the text;
 */
- (TMTextFieldRowItem *)addTextFieldRowItemWithHintText:(NSString *)hintText placeHolder:(NSString *)placeHolder text:(NSString *)text textFieldTextDidChange:(void (^)(NSString *text))block;
- (TMTextFieldRowItem *)addTextFieldRowItemWithHintText:(NSString *)hintText placeHolder:(NSString *)placeHolder text:(NSString *)text observee:(id)object keyPath:(NSString *)keypath;
@end