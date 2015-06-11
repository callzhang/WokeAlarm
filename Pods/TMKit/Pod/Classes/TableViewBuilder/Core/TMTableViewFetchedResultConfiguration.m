//
//  TMTableViewFetchedResultConfiguration.m
//  Pods
//
//  Created by Zitao Xiong on 6/1/15.
//
//

#import "TMTableViewFetchedResultConfiguration.h"
#import "TMRowItem.h"

@implementation TMTableViewFetchedResultConfiguration
- (id)createdRowItemForMangedObject:(id)managedObject {
    Class rowItemClass = NSClassFromString(self.rowItemClassName);
    NSParameterAssert([rowItemClass isSubclassOfClass:[TMRowItem class]]);
    TMRowItem *rowItem = [[rowItemClass alloc] init];
    rowItem.managedObject = managedObject;
    if ([self.delegate respondsToSelector:@selector(configuration:didCreateRowItem:forMangagedObject:)]) {
        [self.delegate configuration:self didCreateRowItem:rowItem forMangagedObject:managedObject];
    }
    else if (self.didCreatedRowItemBlock) {
        self.didCreatedRowItemBlock(self, rowItem, managedObject);
    }
    
    return rowItem;
}

- (Class)rowItemClass {
    return NSClassFromString(self.rowItemClassName);
}

- (instancetype)initWithRowItemClassName:(NSString *)rowItemClassName {
    self = [super init];
    if (self) {
        _rowItemClassName = rowItemClassName;
    }
    
    return self;
}
@end
