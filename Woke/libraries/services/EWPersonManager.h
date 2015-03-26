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
#import "GCDSingleton.h"
#import "EWPerson+Woke.h"

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

GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWPersonManager);

/**
 Possible wakees fetched from server
 */
@property (nonatomic) NSMutableArray *wakeeList;
@property BOOL isFetchingWakees;

//- (EWPerson *)findOrCreatePersonWithParseObject:(PFUser *)user;
- (EWPerson *)getPersonByServerID:(NSString *)ID error:(NSError **)error;
- (void)getWakeesInBackgroundWithCompletion:(VoidBlock)block;
- (NSArray *)getWakeesInContext:(NSManagedObjectContext *)context error:(NSError **)error;
/**
 *  The main method to get next person to wake up
 *
 *  The method will grab next person if it there is still a person in the list returned earlier from server
 *
 *  When the list is empty, and no other thread is calling the server for the wakee list, the method will call the server again to replenish the list. However, when the isFetchingWakees is YES, the object will wait until the fetch finishes, and then return with the block.
 *
 *  @discussion The returned person will never be ones that were skipped by user with the same statement.
 *
 *  @return An instance of EWPerson
 */
- (void)nextWakeeWithCompletion:(void (^)(EWPerson *person))block;



/**
 Check from server at login.
 Fetch current state of currentUser with a custom function to server
 Get a json from server that includes all currentUser's value and relation
 Check if any change is needed.
 */
//+ (void)updateMe;

//Friendship
- (void)requestFriend:(EWPerson *)person completion:(void (^)(EWFriendshipStatus status, NSError *error))completion;
- (void)acceptFriend:(EWPerson *)person completion:(void (^)(EWFriendshipStatus status, NSError *error))completion;
- (void)unfriend:(EWPerson *)person completion:(BoolErrorBlock)completion;

//- (void)sendFriendRequestToPerson:(EWPerson *)person completion:(void (^)(EWFriendRequest *request, NSError *error))block;
//- (void)sendFriendAcceptToPerson:(EWPerson *)person completion:(void (^)(EWFriendRequest *request, NSError *error))block;
//- (void)sendUnfriendStatusToPerson:(EWPerson *)person completion:(BoolErrorBlock)block;
- (void)testGenerateFriendRequestFrom:(EWPerson *)person completion:(void (^)(EWFriendRequest *request, NSError *error))block;

@end
