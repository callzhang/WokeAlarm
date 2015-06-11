//
//  TMSegmentedControlRowItem.m
//  Pods
//
//  Created by Zitao Xiong on 5/8/15.
//
//

#import "TMSegmentedControlRowItem.h"
#import "TMSegmentedControlTableViewCell.h"

@implementation TMSegmentedControlRowItem
+ (NSString *)reuseIdentifier {
    return NSStringFromClass([TMSegmentedControlTableViewCell class]);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (id)cellForRow {
    TMSegmentedControlTableViewCell *cell = [super cellForRow];
    
    return cell;
}
@end
