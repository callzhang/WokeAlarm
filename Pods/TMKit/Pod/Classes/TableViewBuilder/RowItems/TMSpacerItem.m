//
//  TMSpacerItem.m
//  Pods
//
//  Created by Zitao Xiong on 5/28/15.
//
//

#import "TMSpacerItem.h"
#import "TMSpacerTableViewCell.h"

@implementation TMSpacerItem
+ (NSString *)reuseIdentifier {
    return NSStringFromClass([TMSpacerTableViewCell class]);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}
@end

@implementation TMSectionItem (TMSpacerItem)
- (TMSpacerItem *)addSpacerItemWithHeight:(CGFloat)height backgroundColor:(UIColor *)backgroundColor {
    TMSpacerItem *item = [[TMSpacerItem alloc] init];
    item.heightForRow = height;
    item.backgroundViewColor = backgroundColor;
    [self addRowItem:item];
    return item;
}

- (TMSpacerItem *)addSpacerItemWithHeight:(CGFloat)height {
    return [self addSpacerItemWithHeight:height backgroundColor:[UIColor clearColor]];
}
@end