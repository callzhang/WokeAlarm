//
//  TMSpacerItem.h
//  Pods
//
//  Created by Zitao Xiong on 5/28/15.
//
//

#import "TMRowItem.h"
#import "TMSectionItem.h"

@interface TMSpacerItem : TMRowItem

@end

@interface TMSectionItem (TMSpacerItem)
- (TMSpacerItem *)addSpacerItemWithHeight:(CGFloat)height backgroundColor:(UIColor *)backgroundColor;
- (TMSpacerItem *)addSpacerItemWithHeight:(CGFloat)height;
@end