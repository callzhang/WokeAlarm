//
//  EWSharedSession.h
//  Woke
//
//  Created by Lei Zhang on 10/26/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWPerson.h"
#import "NSManagedObject+MagicalFinders.h"
#import "GCDSingleton.h"


@interface EWSession : NSObject

@property (nonatomic, assign) BOOL isSchedulingAlarm;
@property (nonatomic, strong) EWPerson *currentUser;
/**
 *  A dictionary of user and statement
 */
@property (nonatomic, strong) NSDictionary *skippedWakees;
@property (nonatomic, strong) NSString *currentUserObjectID;//for archieving
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSString *cachePath;
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER_WITH_ACCESSOR(EWSession, sharedSession)

+ (NSManagedObjectContext *)mainContext;

@end
