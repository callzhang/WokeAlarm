//
//  NSDictionary+KeyPathAccess.h
//  Woke
//
//  Created by Lee on 12/14/14.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary(KeyPathAccess)
/**
 *  Set value to a immutable dictionary's kay path
 *
 *  @param value   value
 *  @param keyPath keyPath divided with "."
 *
 *  @return a new NSDictionary instance
 */
- (instancetype)setValue:(id)value forImmutableKeyPath:(NSString *)keyPath;
@end
