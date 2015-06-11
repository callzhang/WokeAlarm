//
//  TMExpandableSectionItem.m
//  Pods
//
//  Created by Zitao Xiong on 5/7/15.
//
//

#import "TMExpandableSectionItem.h"
#import "EXTKeyPathCoding.h"
#import "FBKVOController+Binding.h"
#import "TMSectionItem+Protected.h"
#import "TMExpandableHeaderFooterView.h"

@implementation TMExpandableSectionItem
+ (NSString *)cellReuseIdentifierForHeader {
    return NSStringFromClass([TMExpandableHeaderFooterView class]);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.heightForHeader = 44;
        self.backgroundColorForHeader = [UIColor whiteColor];
    }
    return self;
}

- (id)viewForHeader {
    TMExpandableHeaderFooterView *cell = [super viewForHeader];
    [self bindKeypath:@keypath(self.titleForHeader) toLabel:cell.textLabel];
    [self bindKeypath:@keypath(self.expand) withChangeBlock:^(id change) {
        cell.expand = [change boolValue];
    }];
    
    [cell.expandButton addTarget:self action:@selector(toggleExpand:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (void)didEndDisplayingHeaderView:(UIView *)view {
    [super didEndDisplayingHeaderView:view];
    
    if ([view isKindOfClass:[TMExpandableHeaderFooterView class]]) {
        TMExpandableHeaderFooterView *cell = (TMExpandableHeaderFooterView *)view;
        [cell.expandButton removeTarget:self action:@selector(toggleExpand:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)prepareForReuse:(UITableViewHeaderFooterView *)view {
    [super prepareForReuse:view];
    if ([view isKindOfClass:[TMExpandableHeaderFooterView class]]) {
        TMExpandableHeaderFooterView *cell = (TMExpandableHeaderFooterView *)view;
        [cell.expandButton removeTarget:self action:@selector(toggleExpand:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)expandSection {
    [self expandSectionWithRowAnimation:UITableViewRowAnimationFade];
}

- (void)unExpandSection {
    [self unExpandSectionWithRowAnimation:UITableViewRowAnimationFade];
}

- (void)expandSectionWithRowAnimation:(UITableViewRowAnimation)rowAnimation {
    self.expand = YES;
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSUInteger i = 0; i < self.numberOfRows; i ++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:self.section]];
    }
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:rowAnimation];
}

- (void)unExpandSectionWithRowAnimation:(UITableViewRowAnimation)rowAnimation {
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSUInteger i = 0; i < self.numberOfRows; i ++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:self.section]];
    }
    self.expand = NO;
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:rowAnimation];
}

- (NSInteger)numberOfRows {
    if (self.expand) {
        return [super numberOfRows];
    }
    else {
        return 0;
    }
}

- (void)toggleExpand:(id)sender {
    if (self.expand) {
        [self unExpandSection];
    }
    else {
        [self expandSection];
    }
}
@end
