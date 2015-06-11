//
// Created by Andrey on 10/11/14.
// Copyright (c) 2014 Andrey Gayvoronsky. All rights reserved.
//

#import "TMPModelValidation.h"
#import <objc/runtime.h>

NSString *const FXFormValidatorErrorDomain = @"FXFormValidation";
NSString *const FXFormInlineValidatorAction = @"action";
static NSDictionary *FXFormBuiltInValidators;

@implementation TMPModelValidator
-(instancetype)init {
	if((self = [super init])) {
		_skipOnEmpty = YES;
		_skipOnError = YES;
		_when = nil;
		_on = @[];
		_except = @[];
	}

	return self;
}

-(instancetype)initWithAttributes:(NSArray *)attributes params:(NSDictionary *)params {
	if((self = [self init])) {
		_attributes = [attributes copy];

		[params enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, __unused BOOL *stop) {
			[self setValue:value forKey:key];
		}];
	}

	return self;
}

-(void)validate:(id)model{
	[self validate:model attributes:nil];
}

-(void)validate:(id)model attributes:(NSArray *)attributes {
	if(attributes) {
		NSMutableSet *intersection = [NSMutableSet setWithArray:_attributes];
		[intersection intersectSet:[NSSet setWithArray:attributes]];
		attributes = [intersection allObjects];
	} else
		attributes = _attributes;


	for(NSString *name in attributes) {
		BOOL skip = ([self skipOnError] && [model hasErrors:name]) || ([self skipOnEmpty] && [self isEmpty:[model valueForKey:name]]);
		if (!(skip)) {
			if(_when == nil || _when(model, name)) {
				[self validate:model attribute:name];
			}
		}
	}
}

-(void)validate:(id)model attribute:(NSString *)attribute {
	NSAssert(attribute, @"Name of attribute can't be nil.");

	NSError *error = [self validateValue:[model valueForKey:attribute]];
	if (error)
		[self addError:model attribute:attribute error:error];
}

-(NSError *)validateValue:(id)value {
	@throw [NSException exceptionWithName:@"TMPModelValidator" reason:[NSString stringWithFormat:@"Expected -validateValue: to be implemented by %@", NSStringFromClass([self class])] userInfo:nil];
}

-(BOOL)isActive:(NSString *)scenario {
	return (!([_except containsObject:scenario]) && (!([_on count]) || [_on containsObject:scenario]));
}

-(void)addError:(id)model attribute:(NSString *)attribute error:(NSError *)error{
	__block NSString *message;

	//TODO: think about optimization of localisation errors mechanism
	if(error && (message = error.localizedDescription)) {
		NSMutableDictionary *params = [error.userInfo mutableCopy];
		params[@"{attribute}"] = attribute;

		[params enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, __unused BOOL *stop) {
			message = [message stringByReplacingOccurrencesOfString:key withString:[NSString stringWithFormat:@"%@", value]];
		}];

		[model addError:attribute message:message];
	}
}

-(BOOL)isEmpty:(id)value {
	if(_isEmpty)
		return _isEmpty(value);

	return  (
		value == nil || [value isKindOfClass:[NSNull class]] ||
		(([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSSet class]] || [value isKindOfClass:[NSOrderedSet class]]) && [value count] < 1) ||
		([value isKindOfClass:[NSString class]] && [(NSString *)value length] < 1)
	);
}

+(TMPModelValidator *)createValidator:(id)type model:(id)model attributes:(NSArray *)attributes params:(NSDictionary *)params {
	TMPModelValidator *validator;

	if([type isKindOfClass:NSClassFromString(@"NSBlock")]) {
		//type is block
		validator = [TMPModelValidator createInlineValidator:type attributes:attributes params:params];
	} else if([type isKindOfClass:[NSString class]]) {
		if([model respondsToSelector:NSSelectorFromString([NSString stringWithFormat:FXFormInlineValidatorMethodSignature, type])]) {
			//type is method of class
			validator = [TMPModelValidator createInlineValidator:type attributes:attributes params:params];
		} else {
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				FXFormBuiltInValidators = @{
						@"boolean": 	[TMPModelBooleanValidator class],
						@"compare": 	[TMPModelCompareValidator class],
						@"default": 	[TMPModelDefaultValueValidator class],
						@"email":		[TMPModelEmailValidator class],
						@"filter":		[TMPModelFilterValidator class],
						@"number":		[TMPModelNumberValidator class],
						@"in":			[TMPModelRangeValidator class],
						@"match":		[TMPModelRegExpValidator class],
						@"required":	[TMPModelRequiredValidator class],
						@"safe":		[TMPModelSafeValidator class],
						@"string":		[TMPModelStringValidator class],
						@"url":			[TMPModelUrlValidator class],
						@"trim":		[TMPModelTrimFilter class],
				};
			});

			//type is valid name of external built-in validator?
			if((type = FXFormBuiltInValidators[type]))
				validator = [TMPModelValidator createExternalValidator:(([type isKindOfClass:[NSString class]]) ? NSClassFromString(type) : (Class) type) attributes:attributes params:params];
		}
	} else if([type isKindOfClass:[TMPModelValidator class]]) {
		//type is instance of TMPModelValidator
		validator = [TMPModelValidator createExternalValidator:[type class] attributes:attributes params:params];
	} else if(class_isMetaClass(object_getClass(type))) {
		//type is a meta class
		validator = [TMPModelValidator createExternalValidator:(Class) type attributes:attributes params:params];
	}

	return validator;
}

+(TMPModelValidator *)createExternalValidator:(Class)className attributes:(NSArray *)attributes params:(NSDictionary *)params {
	if(className) {
		id validator = [className alloc];

		if (validator && [validator isKindOfClass:[TMPModelValidator class]])
			return [validator initWithAttributes:attributes params:params];
	}

	return nil;
}

+(TMPModelValidator *)createInlineValidator:(id)type attributes:(NSArray *)attributes params:(NSDictionary *)params {
	if(!([params isKindOfClass:[NSMutableDictionary class]]))
		params = ((params) ? [params mutableCopy] : [[NSMutableDictionary alloc] init]);

	((NSMutableDictionary *)params)[FXFormInlineValidatorAction] = [type copy];
	return [[TMPModelInlineValidator alloc] initWithAttributes:attributes params:params];
}
@end