//
//  EWUtil.h
//  EarlyWorm
//
//  Created by Lei on 8/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#define logLevelSymbols         @[@"***", @"!!!", @"@@@", @"==="]

@interface EWUtil : NSObject

+ (NSString *)UUID;
//+ (NSString *)ADID;
+ (void)clearMemory;
/**
 Parse number into dictionary.
 E.g.
 8.30 would translate to: dic<hour: 8, minute: 30>
 */
+ (NSDictionary *)timeFromNumber:(double)number;
+ (double)numberFromTime:(NSDictionary *)dic;
+ (BOOL) isMultitaskingSupported;

//logging
+ (void)initLogging;
//void EWLog(NSString *format,...);

@end

@interface NSArray(Extend)
- (NSString *)string;
@end
