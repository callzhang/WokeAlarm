//
//  TMTuple.m
//  Pods
//
//  Created by Zitao Xiong on 6/15/15.
//  Ref: TMTuple.h by Josh Abernathy
//

#import <Foundation/Foundation.h>
#import "metamacros.h"

/// Creates a new tuple with the given values. At least one value must be given.
/// Values can be nil.
#define TMTuplePack(...) \
TMTuplePack_(__VA_ARGS__)

/// Declares new object variables and unpacks a TMTuple into them.
///
/// This macro should be used on the left side of an assignment, with the
/// tuple on the right side. Nothing else should appear on the same line, and the
/// macro should not be the only statement in a conditional or loop body.
///
/// If the tuple has more values than there are variables listed, the excess
/// values are ignored.
///
/// If the tuple has fewer values than there are variables listed, the excess
/// variables are initialized to nil.
///
/// Examples
///
///   TMTupleUnpack(NSString *string, NSNumber *num) = [TMTuple tupleWithObjects:@"foo", @5, nil];
///   NSLog(@"string: %@", string);
///   NSLog(@"num: %@", num);
///
///   /* The above is equivalent to: */
///   TMTuple *t = [TMTuple tupleWithObjects:@"foo", @5, nil];
///   NSString *string = t[0];
///   NSNumber *num = t[1];
///   NSLog(@"string: %@", string);
///   NSLog(@"num: %@", num);
#define TMTupleUnpack(...) \
TMTupleUnpack_(__VA_ARGS__)

/// A sentinel object that represents nils in the tuple.
///
/// It should never be necessary to create a tuple nil yourself. Just use
/// +tupleNil.
@interface TMTupleNil : NSObject <NSCopying, NSCoding>
/// A singleton instance.
+ (TMTupleNil *)tupleNil;
@end


/// A tuple is an ordered collection of objects. It may contain nils, represented
/// by TMTupleNil.
@interface TMTuple : NSObject <NSCoding, NSCopying, NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger count;

/// These properties all return the object at that index or nil if the number of
/// objects is less than the index.
@property (nonatomic, readonly) id first;
@property (nonatomic, readonly) id second;
@property (nonatomic, readonly) id third;
@property (nonatomic, readonly) id fourth;
@property (nonatomic, readonly) id fifth;
@property (nonatomic, readonly) id last;

/// Creates a new tuple out of the array. Does not convert nulls to nils.
+ (instancetype)tupleWithObjectsFromArray:(NSArray *)array;

/// Creates a new tuple out of the array. If `convert` is YES, it also converts
/// every NSNull to TMTupleNil.
+ (instancetype)tupleWithObjectsFromArray:(NSArray *)array convertNullsToNils:(BOOL)convert;

/// Creates a new tuple with the given objects. Use TMTupleNil to represent
/// nils.
+ (instancetype)tupleWithObjects:(id)object, ... NS_REQUIRES_NIL_TERMINATION;

/// Returns the object at `index` or nil if the object is a TMTupleNil. Unlike
/// NSArray and friends, it's perfectly fine to ask for the object at an index
/// past the tuple's count - 1. It will simply return nil.
- (id)objectAtIndex:(NSUInteger)index;

/// Returns an array of all the objects. TMTupleNils are converted to NSNulls.
- (NSArray *)allObjects;

/// Appends `obj` to the receiver.
///
/// obj - The object to add to the tuple. This argument may be nil.
///
/// Returns a new tuple.
- (instancetype)tupleByAddingObject:(id)obj;

@end

@interface TMTuple (ObjectSubscripting)
/// Returns the object at that index or nil if the number of objects is less
/// than the index.
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
@end

/// This and everything below is for internal use only.
///
/// See TMTuplePack() and TMTupleUnpack() instead.
#define TMTuplePack_(...) \
([TMTuple tupleWithObjectsFromArray:@[ metamacro_foreach(TMTuplePack_object_or_TMtuplenil,, __VA_ARGS__) ]])

#define TMTuplePack_object_or_TMtuplenil(INDEX, ARG) \
(ARG) ?: TMTupleNil.tupleNil,

#define TMTupleUnpack_(...) \
metamacro_foreach(TMTupleUnpack_decl,, __VA_ARGS__) \
\
int TMTupleUnpack_state = 0; \
\
TMTupleUnpack_after: \
; \
metamacro_foreach(TMTupleUnpack_assign,, __VA_ARGS__) \
if (TMTupleUnpack_state != 0) TMTupleUnpack_state = 2; \
\
while (TMTupleUnpack_state != 2) \
if (TMTupleUnpack_state == 1) { \
goto TMTupleUnpack_after; \
} else \
for (; TMTupleUnpack_state != 1; TMTupleUnpack_state = 1) \
[TMTupleUnpackingTrampoline trampoline][ @[ metamacro_foreach(TMTupleUnpack_value,, __VA_ARGS__) ] ]

#define TMTupleUnpack_state metamacro_concat(TMTupleUnpack_state, __LINE__)
#define TMTupleUnpack_after metamacro_concat(TMTupleUnpack_after, __LINE__)
#define TMTupleUnpack_loop metamacro_concat(TMTupleUnpack_loop, __LINE__)

#define TMTupleUnpack_decl_name(INDEX) \
metamacro_concat(metamacro_concat(TMTupleUnpack, __LINE__), metamacro_concat(_var, INDEX))

#define TMTupleUnpack_decl(INDEX, ARG) \
__strong id TMTupleUnpack_decl_name(INDEX);

#define TMTupleUnpack_assign(INDEX, ARG) \
__strong ARG = TMTupleUnpack_decl_name(INDEX);

#define TMTupleUnpack_value(INDEX, ARG) \
[NSValue valueWithPointer:&TMTupleUnpack_decl_name(INDEX)],

@interface TMTupleUnpackingTrampoline : NSObject

+ (instancetype)trampoline;
- (void)setObject:(TMTuple *)tuple forKeyedSubscript:(NSArray *)variables;

@end
