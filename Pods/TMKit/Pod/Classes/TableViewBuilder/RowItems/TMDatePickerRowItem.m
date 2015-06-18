//
//  TMDatePickerRowItem.m
//  TMKit
//
//  Created by Zitao Xiong on 4/26/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMDatePickerRowItem.h"
#import "TMDatePickerTableViewCell.h"
#import "NSDate+MTDates.h"
#import "TMInlineDatePickerRowItem.h"
#import "TMSectionItem.h"
#import "FBKVOController+Binding.h"
#import "TMKit.h"
@implementation TMDatePickerConfigurator
- (instancetype)init {
    self = [super init];
    if (self) {
        self.datePickerMode = UIDatePickerModeDateAndTime;
        self.locale = [NSLocale currentLocale];
        self.calendar = [NSCalendar currentCalendar];
        self.timeZone = nil;
        self.date = [NSDate date];
        self.minimumDate = nil;
        self.maximumDate = nil;
//        self.countDownDuration = 0.0;
//        self.minuteInterval = 1;
    }
    return self;
}

- (void)configureDatePicker:(UIDatePicker *)picker {
    picker.datePickerMode = self.datePickerMode;
    picker.locale = self.locale;
    picker.calendar = self.calendar;
    picker.timeZone = self.timeZone;
    picker.date = self.date;
    picker.minimumDate = self.minimumDate;
    picker.maximumDate = self.maximumDate;
//    picker.countDownDuration = self.countDownDuration;
//    picker.minuteInterval = self.minuteInterval;
}

- (void)updateFromDatePicker:(UIDatePicker *)picker {
    self.datePickerMode = picker.datePickerMode;
    self.locale = picker.locale;
    self.calendar = picker.calendar;
    self.timeZone = picker.timeZone;
    self.date = picker.date;
    self.minimumDate = picker.minimumDate;
    self.maximumDate = picker.maximumDate;
//    self.countDownDuration = picker.countDownDuration;
//    self.minuteInterval = picker.minuteInterval;
}

- (id)copyWithZone:(NSZone *)zone
{
    id theCopy = [[[self class] allocWithZone:zone] init];  // use designated initializer
    
    [theCopy setDatePickerMode:self.datePickerMode];
    [theCopy setLocale:[self.locale copy]];
    [theCopy setCalendar:[self.calendar copy]];
    [theCopy setTimeZone:[self.timeZone copy]];
    [theCopy setDate:[self.date copy]];
    [theCopy setMinimumDate:[self.minimumDate copy]];
    [theCopy setMaximumDate:[self.maximumDate copy]];
    
    return theCopy;
}
@end

@implementation TMDatePickerRowItem
- (instancetype)init {
    self = [super init];
    if (self) {
        self.configurator = [TMDatePickerConfigurator new];
        self.configurator.datePickerMode = UIDatePickerModeDate;
        
        self.inlineDatePickerRowItem = [TMInlineDatePickerRowItem new];
        self.format = @"yyyy/MM/dd";
        self.localized = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.leadingConstantForDateLabel = 150;
        self.titleLabelSpacing = 10;
    }
    return self;
}

+ (NSString *)reuseIdentifier {
    return @"TMDatePickerTableViewCell";
}

- (UITableViewCell *)cellForRow {
    TMDatePickerTableViewCell *cell = (id) [super cellForRow];
    
    if ([cell isKindOfClass:[TMDatePickerTableViewCell class]]) {
        cell.titleLabelSpacingLayoutConstraint.constant = self.titleLabelSpacing;
        cell.dateLabelToLeadingMinimumSpacingConstraint.constant = self.leadingConstantForDateLabel;
        cell.titleTextLabel.text = self.title;
    }
    
    @weakify(self);
    [self bindKeypath:@keypath(self.configurator.date) withChangeBlock:^(id change) {
        @strongify(self);
        if ([cell isKindOfClass:[TMDatePickerTableViewCell class]]) {
            cell.cellTextLabel.text = [self.configurator.date mt_stringFromDateWithFormat:self.format localized:self.localized];
        }
        if (self.didValueChangeHandler) {
            self.didValueChangeHandler(self);
        }
    }];
    
    return cell;
}

- (void)didSelectRow {
    if (self.expand) {
        self.expand = NO;
    }
    else {
        self.expand = YES;
    }
}

- (void)setExpand:(BOOL)expand {
    _expand = expand;
    
    if (expand) {
        TMInlineDatePickerRowItem *rowItem = [TMInlineDatePickerRowItem new];
        rowItem.configurator = self.configurator;
        
        [self.sectionItem insertObject:rowItem inRowItemsAtIndex:self.indexPath.row + 1];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.indexPath.row + 1 inSection:self.indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        self.inlineDatePickerRowItem = rowItem;
    }
    else {
        NSIndexPath *indexPath = self.indexPath;
        [self.sectionItem removeObjectFromRowItemsAtIndex:indexPath.row + 1];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
        
        self.inlineDatePickerRowItem = nil;
    }
}

- (id)copyWithZone:(NSZone *)zone {
    TMDatePickerRowItem *theCopy = [super copyWithZone:zone];
    
    [theCopy setConfigurator:[self.configurator copy]];
    [theCopy setLeadingConstantForDateLabel:self.leadingConstantForDateLabel];
    [theCopy setTitleLabelSpacing:self.titleLabelSpacing];
    [theCopy setTitle:[self.title copy]];
    [theCopy setFormat:[self.format copy]];
    [theCopy setLocalized:self.localized];
//    [theCopy setExpand:self.expand];
    [theCopy setInlineDatePickerRowItem:nil];
    [theCopy setDidValueChangeHandler:self.didValueChangeHandler];
    
    return theCopy;
}
@end

@implementation TMSectionItem (DatePickerRowItem)
- (TMDatePickerRowItem *)addDatePickerRowItemWithDate:(NSDate *)date title:(NSString *)title observee:(id)object keyPath:(NSString *)keypath{
    TMDatePickerRowItem *rowItem = [TMDatePickerRowItem new];
    rowItem.configurator.date = date;
    rowItem.title = title;
    
    [rowItem setDidValueChangeHandler:^(TMDatePickerRowItem *item) {
        [object setValue:item.configurator.date forKey:keypath];
    }];
    
    [self addRowItem:rowItem];
    return rowItem;
}
@end
