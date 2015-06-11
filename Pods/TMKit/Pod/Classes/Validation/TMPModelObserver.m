//
// Created by Andrey on 15/11/14.
// Copyright (c) 2014 Andrey Gayvoronsky. All rights reserved.
//

#import "TMPModelValidation.h"
#import "TMPModelObserver.h"

@interface TMPModelObserver()
@property(nonatomic, strong) id model;
@property(nonatomic, strong) NSMutableSet *attributes;
@property(nonatomic, strong) NSSet *except;
@property(nonatomic, assign) BOOL manual;
@end

@implementation TMPModelObserver
-(instancetype)initWithModel:(id<TMPModel>)model {
	if((self = [self init])) {
		_model = model;
		_except = [NSSet set];
		_attributes = [NSMutableSet set];
	}

	return self;
}

-(void)observe:(NSArray *)attributes except:(NSArray *)except {
	@synchronized (self) {
		//stop to observe?
		if (attributes && [attributes count] == 0) {
			[self removeObserver];
			return;
		}

		_manual = (attributes != nil);
		_except = (except ? [NSSet setWithArray:except] : [NSSet set]);
		self.attributes = [NSMutableSet setWithArray:(_manual ? attributes : [_model activeAttributes])];
	}
}

-(void)setAttributes:(NSMutableSet *)attributes {
	NSMutableSet *delete = [NSMutableSet setWithSet:_attributes];
	[delete minusSet:attributes];
	[delete unionSet:_except];

	//remove outdated
	for(NSString *name in delete) {
		if([_attributes containsObject:name])
			[_model removeObserver:self forKeyPath:name];
	}

	//add new
	[attributes minusSet:_except];
	for(NSString *name in attributes) {
		if(!([_attributes containsObject:name]))
			[_model addObserver:self forKeyPath:name options:NSKeyValueObservingOptionNew context:nil];
	}

	_attributes = attributes;
}

-(void)refresh {
	if(!(_manual))
		self.attributes = [NSMutableSet setWithArray:[_model activeAttributes]];
}

-(void)dealloc {
	[self removeObserver];
}

-(void)removeObserver {
    @try {
        for(NSString *name in _attributes) {
            [_model removeObserver:self forKeyPath:name];
        }
    }
    @catch (NSException *exception) {}
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[(id<TMPModel>)_model clearErrors:keyPath];
	[(id<TMPModel>)_model validate:@[keyPath]];
}
@end