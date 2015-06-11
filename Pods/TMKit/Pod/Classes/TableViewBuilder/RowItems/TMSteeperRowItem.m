//
//  TMSteeperRowItem.m
//  Pods
//
//  Created by Zitao Xiong on 5/8/15.
//
//

#import "TMSteeperRowItem.h"
#import "TMStepperTableViewCell.h"
#import "FBKVOController+Binding.h"
#import "EXTKeyPathCoding.h"

@implementation TMSteeperRowItem
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.continuous = YES;
        self.autorepeat = YES;
        self.wraps = YES;
        self.value = 0;
        self.minimumValue = 0;
        self.maximumValue = 100;
        self.stepValue = 1;
        self.steeperFormatText = @"%@%.0f";
    }
    return self;
}
+ (NSString *)reuseIdentifier {
    return NSStringFromClass([TMStepperTableViewCell class]);
}

- (id)cellForRow {
    TMStepperTableViewCell *cell = [super cellForRow];
    
    [self bindKeypath:@keypath(self.value) withChangeBlock:^(id change) {
        if (!self.steeperFormatText) {
            return ;
        }
        
        double value = [change doubleValue];
        cell.cellTextLabel.text = [NSString stringWithFormat:self.steeperFormatText, self.text, value];
    }];
    
    cell.cellStepper.continuous = self.continuous;
    cell.cellStepper.autorepeat = self.autorepeat;
    cell.cellStepper.wraps = self.wraps;
    cell.cellStepper.value = self.value;
    cell.cellStepper.minimumValue = self.minimumValue;
    cell.cellStepper.maximumValue = self.maximumValue;
    cell.cellStepper.stepValue = self.stepValue;
    
    
    return cell;
}

- (void)willDisplayCell:(TMStepperTableViewCell *)cell {
    [super willDisplayCell:cell];
    [cell.cellStepper addTarget:self action:@selector(onStepperValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)didEndDisplayingCell:(TMStepperTableViewCell *)cell {
    [super didEndDisplayingCell:cell];
    [cell.cellStepper removeTarget:self action:@selector(onStepperValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)onStepperValueChanged:(UIStepper *)stepper {
    self.value = stepper.value;
    if (self.stepperValueChangedHandler) {
        self.stepperValueChangedHandler(self);
    }
}
@end
