//
//  TMSearchFilterring.h
//  Pods
//
//  Created by Zitao Xiong on 6/4/15.
//
//

@class TMTableViewBuilder;
@protocol TMSearchFilterring

@property (nonatomic, weak) TMTableViewBuilder *filterringTableViewBuilder;
//TODO: more predicate and filtering
//TODO: core data managed section support
- (NSPredicate *)searchPredicateWithText:(NSString *)text;
- (BOOL)shouldDeepCopyRowItems;
@end