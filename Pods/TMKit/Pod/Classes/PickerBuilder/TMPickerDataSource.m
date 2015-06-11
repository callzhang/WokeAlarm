//
//  TMPickerDataSource.m
//  TMKit
//
//  Created by Zitao Xiong on 4/28/15.
//  Copyright (c) 2015 Zitao Xiong. All rights reserved.
//

#import "TMPickerDataSource.h"
#import "TMPickerBuilder.h"
#import "TMPickerComponent.h"

@interface TMPickerDataSource()
@property (nonatomic, weak) TMPickerBuilder *pickerBuilder;
@end

@implementation TMPickerDataSource
- (instancetype)initWithPickerBuilder:(TMPickerBuilder *)builder {
    self = [super init];
    if (self) {
        self.pickerBuilder = builder;
    }
    return self;
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return [self.pickerBuilder numberOfComponent];
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    TMPickerComponent *pickerComponent = [self.pickerBuilder componentAtIndex:component];
    return pickerComponent.numberOfRows;
}
@end
