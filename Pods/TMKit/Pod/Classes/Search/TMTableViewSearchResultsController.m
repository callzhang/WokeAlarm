//
//  TMTableViewSearchResultsController.m
//  Pods
//
//  Created by Zitao Xiong on 6/4/15.
//
//

#import "TMTableViewSearchResultsController.h"
#import "TMSectionItem.h"

@interface TMTableViewSearchResultsController ()

@end

@implementation TMTableViewSearchResultsController
@synthesize tableViewBuilder = _tableViewBuilder;
@synthesize filterringTableViewBuilder = _filterringTableViewBuilder;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tableViewBuilder = [[TMTableViewBuilder alloc] initWithTableView:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableViewBuilder.tableView = self.tableView;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self.tableViewBuilder removeAllSectionItems];
    NSPredicate *searchPredicate = [self searchPredicateWithText:searchController.searchBar.text];
    
    NSMutableArray *sections = [NSMutableArray array];
    [self.filterringTableViewBuilder tm_eachSectionItem:^(TMSectionItem *sectionItem) {
        NSArray *filterRowItems = [sectionItem filterRowItemsUsingPredicate:searchPredicate];
        if (filterRowItems.count > 0) {
            //Using Deep copy
            TMSectionItem *newSectionItem = sectionItem.copy;
            NSArray *copiedRowitems;
            if ([self shouldDeepCopyRowItems]) {
                copiedRowitems = [[NSArray alloc] initWithArray:filterRowItems copyItems:YES];
            }
            else {
                copiedRowitems = [[NSArray alloc] initWithArray:filterRowItems copyItems:NO];
            }
            
            [newSectionItem insertRowItems:copiedRowitems atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, copiedRowitems.count)]];
            [sections addObject:newSectionItem];
        }
    }];
    
    if (sections.count) {
        [self.tableViewBuilder insertSectionItems:sections atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sections.count)]];
    }
    
    [self.tableViewBuilder reloadData];
}

- (NSPredicate *)searchPredicateWithText:(NSString *)text {
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"(text CONTAINS[cd] %@) OR (detailText CONTAINS[cd] %@)", text, text];
    return searchPredicate;
}

- (BOOL)shouldDeepCopyRowItems {
    return YES;
}
@end
