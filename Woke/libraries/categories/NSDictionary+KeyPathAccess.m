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
    if ([keyPath isEqualToString:@""]) {
        DDLogWarn(@"%s passed in empty path", __func__);
        return self;
    }
    NSArray *paths = [keyPath componentsSeparatedByString:@"."];
    NSMutableDictionary *newDictionary = [self mutableCopy];
    if (paths.count == 1) {
        //last keypath, set value directly
        newDictionary[paths.firstObject] = value;
    }else{
        //divide the task
        NSString *childPath = paths[1];
        for (NSUInteger i = 2; i<paths.count; i++) {
            childPath = [childPath stringByAppendingString:[NSString stringWithFormat:@".%@", paths[i]]];
        }
        NSDictionary *childDic = self[paths.firstObject] ?: [NSDictionary new];
        childDic = [childDic setValue:value forImmutableKeyPath:childPath];
        newDictionary[paths.firstObject] = childDic;
    }
    return newDictionary.copy;
}

- (instancetype)addValue:(id)value toArrayAtImmutableKeyPath:(NSString *)keyPath{
    NSArray *paths = [keyPath componentsSeparatedByString:@"."];
    NSMutableDictionary *newDictionary = [self mutableCopy];
    if (paths.count == 1) {
        //last keypath, add value directly
        NSMutableArray *array = [(NSArray *)newDictionary[paths.firstObject] mutableCopy]?:[NSMutableArray array];
        [array addObject:value];
        newDictionary[paths.firstObject] = array.copy;
    }else{
        //divide the task
        NSString *childPath = paths[1];
        for (NSUInteger i = 2; i<paths.count; i++) {
            childPath = [childPath stringByAppendingString:[NSString stringWithFormat:@".%@", paths[i]]];
        }
        NSDictionary *childDic = self[paths.firstObject] ?: [NSDictionary new];
        childDic = [childDic setValue:value forImmutableKeyPath:childPath];
        newDictionary[paths.firstObject] = childDic;
    }
    return newDictionary.copy;
}

@end
