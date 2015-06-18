//
//  FBKVOController+Binding.m
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

#import "FBKVOController+Binding.h"
#import "TMKit.h"
#import "TMTuple.h"
#import "TMBlockExecutor.h"
//#import "NSObject+MTKObserving.h"


@implementation FBKVOController (Binding)
- (void)bindObserver:(NSObject *)observer keyPath:(NSString *)observerKeyPath toSubject:(NSObject *)subject keyPath:(NSString *)subjectKeyPath {
    [self bindObserver:observer keyPath:observerKeyPath toSubject:subject keyPath:subjectKeyPath withValueTransform:nil];
}

- (void)bindObserver:(NSObject *)observer keyPath:(NSString *)observerKeyPath toSubject:(NSObject *)subject keyPath:(NSString *)subjectKeyPath withValueTransform:(id (^)(id))transformBlock {
    [self observe:observer keyPath:observerKeyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        id newValue = change[NSKeyValueChangeNewKey];
        if (transformBlock) {
            newValue = transformBlock(newValue);
        }
        
        [subject setValue:newValue forKeyPath:subjectKeyPath];
    }];
}

- (void)observe:(id)observer keyPath:(NSString *)keyPath block:(void (^)(id observer, id object, id change))block {
    [self observe:observer keyPath:keyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        id newValue = change[NSKeyValueChangeNewKey];
        if (block) {
            block(observer, object, newValue);
        }
    }];
}

- (void)observe:(id)observer keyPaths:(NSArray *)keyPaths block:(void (^)(id, id, id))block {
    [self observe:observer keyPaths:keyPaths options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        id newValue = change[NSKeyValueChangeNewKey];
        if (block) {
            block(object, object, newValue);
        }
    }];
}



@end

@implementation NSObject (SVRBinding)
- (void)bindKeyPath:(NSString *)keyPath toObject:(id)object toKeyPath:(NSString *)anotherKeypath {
    [self bindKeyPath:keyPath toObject:object toKeyPath:anotherKeypath map:nil];
}

- (void)bindKeyPath:(NSString *)keyPath toObject:(id)object toKeyPath:(NSString *)anotherKeypath map:(id (^)(id change))mapBlock {
    [self bindKeypath:keyPath toObject:object withChangeBlock:^(id object, id change) {
        id value = change;
        if (mapBlock) {
            value = mapBlock(value);
        }
        [object setValue:value forKeyPath:anotherKeypath];
    }];
}

- (void)bindKeypath:(NSString *)keyPath toLabel:(UILabel *)textLabel map:(id (^)(id))block {
    [self bindKeypath:keyPath toObject:textLabel withChangeBlock:^(UILabel *label, id change) {
        if (change) {
            if (block) {
                change = block(change);
            }
            if ([change isKindOfClass:[NSString class]]) {
                label.text = change;
            }
            else if ([change isKindOfClass:[NSNumber class]]) {
                label.text = [(NSNumber *)change stringValue];
            }
            else if ([change isKindOfClass:[NSAttributedString class]]) {
                label.attributedText = change;
            }
            else {
                DDLogError(@"change %@ not supported", change);
                label.text = @"";
            }
        }
        else {
            label.text = @"";
        }
    }];
}

- (void)bindKeypath:(NSString *)keyPath toLabel:(UILabel *)textLabel {
    [self bindKeypath:keyPath toLabel:textLabel map:nil];
}


- (void)bindKeypath:(NSString *)keyPath toImageView:(UIImageView *)imageView {
    [self bindKeypath:keyPath toObject:imageView withChangeBlock:^(UIImageView *aImageView, id change) {
        if ([change isKindOfClass:[UIImage class]]) {
            aImageView.image = change;
        }
        else {
            DDLogVerbose(@"image :%@ not handle", change);
        }
    }];
}

- (void)bindKeypath:(NSString *)keyPath toObject:(id)toObject withChangeBlock:(void (^)(id toObject, id change))block {
    [self.KVOController observe:self keyPath:keyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        id changeObject = [change valueForKey:NSKeyValueChangeNewKey];
        if (block) {
            if ([changeObject isKindOfClass:[NSNull class]]) {
                changeObject = nil;
            }
            block(toObject, changeObject);
        }
    }];
}

- (void)bindKeypath:(NSString *)keyPath withChangeBlock:(void (^)(id change))block {
    [self.KVOController observe:self keyPath:keyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        id changeObject = [change valueForKey:NSKeyValueChangeNewKey];
        if (block) {
            if ([changeObject isKindOfClass:[NSNull class]]) {
                changeObject = nil;
            }
            block(changeObject);
        }
    }];
}

- (void)unbind {
    [self.KVOController unobserveAll];
}

- (void)bindKeypath:(NSString *)keyPath toKeyPath:(NSString *)anothKeyPath {
    [self bindKeypath:keyPath toKeyPath:anothKeyPath tranformBlock:nil];
}

- (void)bindKeypath:(NSString *)keyPath toKeyPath:(NSString *)anothKeyPath tranformBlock:(id (^)(id))tranformBlock {
   [self bindKeypath:keyPath withChangeBlock:^(id change) {
       if (tranformBlock) {
           change = tranformBlock(change);
       }
       [self setValue:change forKeyPath:anothKeyPath];
   }];
}
#pragma mark - 
- (void)tm_twoWayBindingWithSourceKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath {
    [self tm_twoWayBindingWithSourceKeyPath:sourceKeyPath toKeyPath:destinationKeyPath transformationBlock:nil];
}

/**
 *  TODO: transform block is not working. it needs to have reversed tranformation. which will 
 *   be used when applied into changes from destination keypath
 *
 *  @param sourceKeyPath       source keypath
 *  @param destinationKeyPath  destination keypath
 *  @param transformationBlock transformed block appled to source change
 */
- (void)tm_twoWayBindingWithSourceKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath transformationBlock:(id (^)(id))transformationBlock {
    [self bindKeypath:sourceKeyPath withChangeBlock:^(id change) {
        id destinationValue = [self valueForKeyPath:destinationKeyPath];
        id transformedValue = change;
//        if (transformationBlock) {
//            transformedValue = transformationBlock(change);
//        }
        if (![destinationValue isEqual:transformedValue]) {
            [self setValue:transformedValue forKeyPath:destinationKeyPath];
        }
    }];

    [self bindKeypath:destinationKeyPath withChangeBlock:^(id change) {
        id sourceValue = [self valueForKeyPath:sourceKeyPath];
        id tranformedValue = change;
        if (![sourceValue isEqual:tranformedValue]) {
            [self setValue:tranformedValue forKeyPath:sourceKeyPath];
        }
    }];
}

- (void)tm_bindKeyPaths:(NSArray *)keyPaths withChangeBlock:(void (^)())block {
    [self.KVOController observe:self keyPaths:keyPaths block:^(id observer, id object, id change) {
        NSArray *values = [self tm_valueForKeyPaths:keyPaths];
        TMTuple *tuple = [TMTuple tupleWithObjectsFromArray:values];
        [TMBlockExecutor invokeNoReturnBlock:block withArguments:tuple];
    }];
}

- (void)tm_combineKeyPaths:(NSArray *)keyPaths toKeyPath:(NSString *)keyPath reduce:(id (^)())reduceBlock {
    [self.KVOController observe:self keyPaths:keyPaths block:^(id observer, id object, id change) {
        NSArray *values = [self tm_valueForKeyPaths:keyPaths];
        TMTuple *tuple = [TMTuple tupleWithObjectsFromArray:values];
        id reduced = [TMBlockExecutor invokeBlock:reduceBlock withArguments:tuple];
        [self setValue:reduced forKeyPath:keyPath];
    }];
}

- (NSArray *)tm_valueForKeyPaths:(NSArray *)keyPaths {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:keyPaths.count];
    for (NSString *keyPath in keyPaths) {
        [array addObject:[self valueForKeyPath:keyPath]];
    }
    return array.copy;
}
@end