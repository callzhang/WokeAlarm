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
    NSArray *paths = [keyPath componentsSeparatedByString:@"."];
    NSMutableDictionary *newDictionary = [self mutableCopy];
    if (paths.count == 1) {
        //last keypath, set value directly
        newDictionary[paths.firstObject] = value;
    }else{
        //divide the task
        NSString *childPath = @"";
        for (NSUInteger i = 1; i<paths.count; i++) {
            childPath = [childPath stringByAppendingString:paths[i]];
        }
        NSDictionary *childDic = self[paths.firstObject] ?: [NSDictionary new];
        childDic = [childDic setValue:value forImmutableKeyPath:childPath];
        newDictionary[paths.firstObject] = childDic;
    }
    return newDictionary.copy;
}
@end
