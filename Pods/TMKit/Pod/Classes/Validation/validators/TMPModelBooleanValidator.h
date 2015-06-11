//
// Created by Andrey on 12/11/14.
// Copyright (c) 2014 Andrey Gayvoronsky. All rights reserved.
//

#import "TMPModelValidator.h"

/**
* TMPModelBooleanValidator checks if the attribute value is a boolean value.
*
* Possible boolean values can be configured via the [[trueValue]] and [[falseValue]] properties.
*/
@interface TMPModelBooleanValidator : TMPModelValidator

/**
* The value representing true status. Defaults to @(YES).
*/
@property(nonatomic, copy) id trueValue;

/**
* The value representing false status. Defaults to @(NO).
*/
@property(nonatomic, copy) id falseValue;
@end