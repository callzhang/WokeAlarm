//
//  TMRadioOptionRowItem.m
//  Pods
//
//  Created by Zitao Xiong on 5/4/15.
//
//

#import "TMRadioOptionTableViewCell.h"
#import "FBKVOController+Binding.h"
#import "TMRadioOptionRowItem.h"
#import "TMKit.h"

@implementation TMRadioOptionRowItem
+ (NSString *)reuseIdentifier {
    return NSStringFromClass([TMRadioOptionTableViewCell class]);
}

- (id)cellForRow {
    TMRadioOptionTableViewCell *cell = [super cellForRow];
    [self bindKeypath:@keypath(self.model.text) toLabel:cell.cellTextLabel];
    [self bindKeypath:@keypath(self.isSelected) withChangeBlock:^(NSNumber *change) {
        if (change.boolValue) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }];
    return cell;
}
@end
