//
//  EWPerson.h
//  EarlyWorm
//
//  Created by Lei on 10/12/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "_EWPerson.h"
#import <Parse/Parse.h>

@import CoreLocation;

@class EWAlarm, EWSocial;

extern NSString * const EWPersonDefaultName;

@interface EWPerson : _EWPerson
@property (nonatomic, strong) CLLocation* location;
@property (nonatomic, strong) UIImage *profilePic;
@property (nonatomic, strong) UIImage *bgImage;
@property (nonatomic, strong) NSDictionary *preference;
@property (nonatomic, strong) NSDictionary *cachedInfo;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, readwrite) NSString *name;

/**
 *  Find or create EWPerson from PFUser
 *
 *  @param user PFUser
 *  @discussion If PFUser isNew or missing name, it will trigger new user sequence and assign default value
 *  @return EWPerson
 */
+ (EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user;


//validate
- (BOOL)validate;

//helper
- (NSString *)genderObjectiveCaseString;
- (float)distance;
- (NSString *)distanceString;
@end
