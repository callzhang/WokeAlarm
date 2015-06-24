//
//  EWSharedSession.m
//  Woke
//
//  Created by Lei Zhang on 10/26/14.
//  Copyright (c) 2014 WokeAlarm.com. All rights reserved.
//

#import "EWSession.h"
#import "EWPerson.h"
#import "FBKVOController.h"



@implementation EWSession
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_WITH_ACCESSOR(EWSession, sharedSession);

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              NSStringFromSelector(@selector(alarmTones)) :  @[@"Autumn Spring", @"Daybreak", @"Drive", @"Parisian Dream", @"Sunny Afternoon", @"Tropical Delight"],
                                                              NSStringFromSelector(@selector(currentAlarmTone)) : @"Autumn Spring",
                                                              }];
}

//- (void)load {
//    EWSession *tmp = nil;
//    @try {
//        tmp = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cachePath];
//    } @catch (NSException *exception) {
//        // log the error.
//        DDLogInfo(@"### Seems the archive uses an old format.");
//        return;
//    }
//    
//    if (tmp) {
//        self.currentUserObjectID = tmp -> _currentUserObjectID;
//    }
//}
//
//- (void)save {
//    [NSKeyedArchiver archiveRootObject:self toFile:self.cachePath];
//    DDLogInfo(@"session saved %@", self);
//}

- (void)setAlarmTones:(NSArray *)alarmTones {
    [[NSUserDefaults standardUserDefaults] setObject:alarmTones forKey:NSStringFromSelector(@selector(alarmTones))];
}

- (NSArray *)alarmTones {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:NSStringFromSelector(@selector(alarmTones))] copy];
}

- (void)setCurrentAlarmTone:(NSString *)currentAlarmTone {
    [[NSUserDefaults standardUserDefaults] setObject:currentAlarmTone forKey:NSStringFromSelector(@selector(currentAlarmTone))];
}

- (NSString *)currentAlarmTone {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:NSStringFromSelector(@selector(currentAlarmTone))] copy];
}

//- (void)setCurrentUserObjectID:(NSString *)currentUserObjectID {
//    if (currentUserObjectID) {
//        EWPerson *me = [EWPerson MR_findFirstByAttribute:EWServerObjectAttributes.objectId withValue:currentUserObjectID];
//        NSParameterAssert([[PFUser currentUser].objectId isEqualToString:me.objectId]);
//        self.currentUser = me;
//    }
//    
//    [[NSUserDefaults standardUserDefaults] setObject:currentUserObjectID forKey:NSStringFromSelector(@selector(currentUserObjectID))];
//}

//- (NSString *)currentUserObjectID {
//    return [[[NSUserDefaults standardUserDefaults] objectForKey:NSStringFromSelector(@selector(currentUserObjectID))] copy];
//}


- (void)setSkippedWakees:(NSMutableDictionary *)skippedWakees {
    [[NSUserDefaults standardUserDefaults] setObject:skippedWakees forKey:NSStringFromSelector(@selector(skippedWakees))];
}

- (NSMutableDictionary *)skippedWakees {
    NSMutableDictionary *skippedWakees = [[NSUserDefaults standardUserDefaults] objectForKey:NSStringFromSelector(@selector(skippedWakees))];
    skippedWakees = skippedWakees ? : [NSMutableDictionary dictionary];
    return [skippedWakees copy];
}

+ (NSManagedObjectContext *)mainContext{
    return [EWSession sharedSession].context;
}



+(BOOL) isFirstTimeLogin{
    
    NSDictionary *option = @{@"firstTime": @"YES"};
    [[NSUserDefaults standardUserDefaults] registerDefaults:option];
    NSString *isString = [[NSUserDefaults standardUserDefaults] valueForKey:@"firstTime"];
    if ([isString isEqualToString:@"YES"]) {
        return YES;
    }
    else{
        return NO;
    }
    
}

+(void)pastFirstTimeLogin{
    [[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:@"firstTime"];
}

//#pragma mark - Persistancy
//
//- (void)encodeWithCoder:(NSCoder *)encoder {
//    [encoder encodeObject:_currentUserObjectID forKey:@"currentUserObjectID"];
//    [encoder encodeObject:_skippedWakees forKey:@"skippedUsers"];
//}
//
//- (id)initWithCoder:(NSCoder *)decoder {
//    self.currentUserObjectID = [decoder decodeObjectForKey:@"currentUserObjectID"];
//    self.skippedWakees = [decoder decodeObjectForKey:@"skippedUsers"];
//    return self;
//}

@end

@implementation EWSession (UserDefaults)


@end