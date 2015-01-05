//
//  NSDictionary+KeyPathAccess.m
//  Woke
//
//  Created by Lee on 12/14/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "NSDictionary+KeyPathAccess.h"

@implementation NSDictionary(KeyPathAccess)
- (instancetype)setValue:(id)value forImmutableKeyPath:(NSString *)keyPath{
    if (!keyPath || [keyPath isEqualToString:@""]) {
        DDLogError(@"%s passed in empty path", __func__);
        return self;
    }
    NSArray *paths = [keyPath componentsSeparatedByString:@"."];
    NSMutableDictionary *mutableDictionary = [self mutableCopy];
    if (paths.count == 1) {
        //last keypath, set value directly
		if (value) {
			mutableDictionary[paths.lastObject] = value;
		}else{
			[mutableDictionary removeObjectForKey:paths.lastObject];
		}
		
    }else{
        //divide the task
        NSString *childPath = paths[1];
        for (NSUInteger i = 2; i<paths.count; i++) {
            childPath = [childPath stringByAppendingString:[NSString stringWithFormat:@".%@", paths[i]]];
        }
        NSDictionary *childDic = self[paths.firstObject] ?: [NSDictionary new];
        childDic = [childDic setValue:value forImmutableKeyPath:childPath];
        mutableDictionary[paths.firstObject] = childDic;
    }
    return mutableDictionary.copy;
}

- (instancetype)addValue:(id)value toArrayAtImmutableKeyPath:(NSString *)keyPath{
	if (!keyPath || [keyPath isEqualToString:@""]) {
		DDLogError(@"%s passed in empty path", __func__);
		return self;
	}
	else if (!value) {
		NSLog(@"%s passed nil as value", __func__);
		return self;
	}
    NSArray *paths = [keyPath componentsSeparatedByString:@"."];
    NSMutableDictionary *mutableDictionary = [self mutableCopy];
    if (paths.count == 1) {
        //last keypath, add value directly
        NSMutableArray *array = [(NSArray *)mutableDictionary[paths.firstObject] mutableCopy]?:[NSMutableArray array];
		if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSSet class]]) {
			for (id obj in value) {
				[array addObject:obj];
			}
		}else{
			[array addObject:value];
		}
        mutableDictionary[paths.lastObject] = array.copy;
    }else{
        //divide the task
        NSString *childPath = paths[1];
        for (NSUInteger i = 2; i<paths.count; i++) {
            childPath = [childPath stringByAppendingString:[NSString stringWithFormat:@".%@", paths[i]]];
        }
        NSDictionary *childDic = self[paths.firstObject] ?: [NSDictionary new];
        childDic = [childDic setValue:value forImmutableKeyPath:childPath];
        mutableDictionary[paths.firstObject] = childDic;
    }
    return mutableDictionary.copy;
}

@end
