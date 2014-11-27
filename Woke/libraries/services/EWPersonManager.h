//
//  EWPersonStore.h
//  EarlyWorm
//
//  Created by Lei on 8/16/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EWStartUpSequence.h"
#import "EWPerson.h"

#define everyoneCheckTimeOut            600 //10min
#define numberOfRelevantUsers           @10 //number of relevant users returned
#define radiusOfRelevantUsers           @-1  //search radius in kilometers for relevant users
#define kDefaultUsername                    @"New User"
#define kEveryoneLastFetched                @"everyone_last_fetched"
#define kEveryone                           @"everyone"
#define kLastCheckedMe                      @"last_checked_me"
#define kCheckMeInternal                    3600 * 24 //1 day

@class EWMediaManager, EWPerson;

@interface EWPersonManager : NSObject

/**
 Possible people that are relevant, fetched from server(TODO)
 */
@property (nonatomic) NSMutableArray *wakeeList;
@property BOOL isFetchingEveryone;

+ (EWPersonManager *)sharedInstance;
//- (EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user;
- (EWPerson *)getPersonByServerID:(NSString *)ID;
- (void)getWakeesInBackgroundWithCompletion:(void (^)(void))block;

/**
 *  The main method to get next person to wake up
 *  When called first time, this method will call the server method to fetch a list of person. 
 *
 *  The method will grab next person if it there is still a person in the list returned earlier from server
 *
 *  When the list is empty, the method will call the server again to replenish the list.
 *
 *  @discussion The returned person will never be ones that were skipped by user and has not updated.
 *
 *  @return An instance of EWPerson
 */
- (EWPerson *)nextWakee;



/**
 Check from server at login.
 Fetch current state of currentUser with a custom function to server
 Get a json from server that includes all currentUser's value and relation
 Check if any change is needed.
 */
//+ (void)updateMe;

@end
