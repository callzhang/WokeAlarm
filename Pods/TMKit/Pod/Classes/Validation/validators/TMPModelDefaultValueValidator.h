//
// Created by Andrey on 12/11/14.
// Copyright (c) 2014 Andrey Gayvoronsky. All rights reserved.
//

#import "TMPModelValidator.h"

FOUNDATION_EXPORT NSString *const FXFormDefaultValueValidatorMethodSignature; //signature for method callback.
typedef id(^FXFormDefaultValueValidatorBlock)(id model, NSString *attribute); //type of block callback

/**
* TMPModelDefaultValueValidator sets the attribute to be the specified default value.
*
* TMPModelDefaultValueValidator is not really a validator. It is provided mainly to allow
* specifying attribute default values when they are empty.
*/
@interface TMPModelDefaultValueValidator : TMPModelValidator

/**
* The default value, model's method(signature:'%@:') or block(signature: 'id(^FXFormDefaultValueValidatorBlock)(id model, NSString *attribute)') that returns the default value which will
* be assigned to the attributes being validated if they are empty.
*/
@property(nonatomic, copy) id value;
@end