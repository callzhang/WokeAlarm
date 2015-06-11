//
//  TMSteeperRowItem.h
//  Pods
//
//  Created by Zitao Xiong on 5/8/15.
//
//

#import "TMRowItem.h"

@interface TMSteeperRowItem : TMRowItem
@property(nonatomic,getter=isContinuous) BOOL continuous; // if YES, value change events are sent any time the value changes during interaction. default = YES
@property(nonatomic) BOOL autorepeat;                     // if YES, press & hold repeatedly alters value. default = YES
@property(nonatomic) BOOL wraps;                          // if YES, value wraps from min <-> max. default = NO

@property(nonatomic) double value;                        // default is 0. sends UIControlEventValueChanged. clamped to min/max
@property(nonatomic) double minimumValue;                 // default 0. must be less than maximumValue
@property(nonatomic) double maximumValue;                 // default 100. must be greater than minimumValue
@property(nonatomic) double stepValue;                    // default 1. must be greater than 0

@property (nonatomic, strong) NSString *steeperFormatText; // default %@%.0f first %@ is self.text, second is self.value


@property (nonatomic, copy) void (^stepperValueChangedHandler)(TMSteeperRowItem *rowItem);
- (void)setStepperValueChangedHandler:(void (^)(TMSteeperRowItem *rowItem))stepperValueChangedHandler;
@end
