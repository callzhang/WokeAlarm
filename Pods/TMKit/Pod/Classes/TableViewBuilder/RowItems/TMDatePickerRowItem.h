//
//  TMDatePickerRowItem.h
//  TMKit
//
//  Created by Zitao Xiong on 4/26/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMRowItem.h"
#import "TMInlineDatePickerRowItem.h"
#import "TMSectionItem.h"

@interface TMDatePickerConfigurator : NSObject<NSCopying>
@property (nonatomic) UIDatePickerMode datePickerMode; // default is UIDatePickerModeDateAndTime

@property (nonatomic, retain) NSLocale   *locale;   // default is [NSLocale currentLocale]. setting nil returns to default
@property (nonatomic, copy)   NSCalendar *calendar; // default is [NSCalendar currentCalendar]. setting nil returns to default
@property (nonatomic, retain) NSTimeZone *timeZone; // default is nil. use current time zone or time zone from calendar

@property (nonatomic, retain) NSDate *date;        // default is current date when picker created. Ignored in countdown timer mode. for that mode, picker starts at 0:00
@property (nonatomic, retain) NSDate *minimumDate; // specify min/max date range. default is nil. When min > max, the values are ignored. Ignored in countdown timer mode
@property (nonatomic, retain) NSDate *maximumDate; // default is nil

//@property (nonatomic) NSTimeInterval countDownDuration; // for UIDatePickerModeCountDownTimer, ignored otherwise. default is 0.0. limit is 23:59 (86,399 seconds). value being set is div 60 (drops remaining seconds).
//@property (nonatomic) NSInteger      minuteInterval;    // display minutes wheel with interval. interval must be evenly divided into 60. default is 1. min is 1, max is 30

- (void)configureDatePicker:(UIDatePicker *)picker;
- (void)updateFromDatePicker:(UIDatePicker *)picker;
@end

@interface TMDatePickerRowItem : TMRowItem
@property (nonatomic, strong) TMDatePickerConfigurator *configurator;
@property (nonatomic, assign) NSInteger leadingConstantForDateLabel;
@property (nonatomic, assign) NSInteger titleLabelSpacing;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *format;
@property (nonatomic, assign) BOOL localized;
@property (nonatomic, assign) BOOL expand;
@property (nonatomic, strong) TMInlineDatePickerRowItem *inlineDatePickerRowItem;

@property (nonatomic, copy) void (^didValueChangeHandler)(TMDatePickerRowItem *item);
@end

@interface TMSectionItem (DatePickerRowItem)
- (TMDatePickerRowItem *)addDatePickerRowItemWithDate:(NSDate *)date title:(NSString *)title observee:(id)object keyPath:(NSString *)keypath;
@end
