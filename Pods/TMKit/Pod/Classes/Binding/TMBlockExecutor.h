//
//  TMBlockExecutor.h
//  Pods
//
//  Created by Zitao Xiong on 6/15/15.
//
//

#import <Foundation/Foundation.h>
#import "TMTuple.h"

@interface TMBlockExecutor : NSObject
// Invokes the given block with the given arguments. All of the block's
// argument types must be objects and it must be typed to return an object.
//
// At this time, it only supports blocks that take up to 15 arguments. Any more
// is just cray.
//
// block     - The block to invoke. Must accept as many arguments as are given in
//             the arguments array. Cannot be nil.
// arguments - The arguments with which to invoke the block. `RACTupleNil`s will
//             be passed as nils.
//
// Returns the return value of invoking the block.
+ (id)invokeBlock:(id)block withArguments:(TMTuple *)arguments;

+ (void)invokeNoReturnBlock:(id)block withArguments:(TMTuple *)arguments;
@end
