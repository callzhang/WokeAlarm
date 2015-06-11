//
//  TMSimpleTableViewController.m
//  Pods
//
//  Created by Zitao Xiong on 5/4/15.
//
//

#import "TMSimpleTableViewController.h"

@interface TMSimpleTableViewController ()

@end

@implementation TMSimpleTableViewController
@synthesize tableViewBuilder = _tableViewBuilder;
@synthesize viewDidLoadCompletionHandler = _viewDidLoadCompletionHandler;
@synthesize viewWillDisappearCompletionHandler = _viewWillDisappearCompletionHandler;
@synthesize resultType = _resultType;

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
    
    if (self.viewDidLoadCompletionHandler) {
        self.viewDidLoadCompletionHandler(self);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.viewWillDisappearCompletionHandler) {
        self.viewWillDisappearCompletionHandler(self, self.resultType);
    }
}

@end
