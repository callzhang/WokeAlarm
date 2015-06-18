//
//  TMRadioRowItem.m
//  Pods
//
//  Created by Zitao Xiong on 5/4/15.
//
//

@import UIKit;
#import "TMRadioRowItem.h"
#import "TMRadioTableViewCell.h"
#import "FBKVOController+Binding.h"
#import "TMSimpleTableViewController.h"
#import "TMRadioOptionRowItem.h"
#import "TMKit.h"

@implementation TMRadioRowItem
+ (NSString *)reuseIdentifier {
    return @"TMRadioTableViewCell";
}

- (instancetype)init {
    return  [self initWithSelectionListWithText:nil selectedIndex:nil];
}

- (instancetype)initWithSelectionListWithText:(NSArray *)texts selectedIndex:(NSNumber *)index {
    self = [super init];
    if (self) {
        NSMutableArray *list = [NSMutableArray array];
        for (NSString *text in texts) {
            [list addObject:[[TMRadioRowItemSelectionModel alloc] initWithText:text context:nil]];
        }
        
        self.selectionModelList = list.copy;
        self.selectedIndex = index;
    }
    
    return self;
}

- (id)cellForRow {
    UITableViewCell<TMRadioRowTableViewCellProtocol> *cell = [super cellForRow];
    
    [self bindKeypath:@keypath(self.text) toLabel:cell.cellTitleLabel];
    [self bindKeypath:@keypath(self.selectedText) toLabel:cell.selectionTextLabel];
    
    return cell;
}

- (void)didSelectRow {
    [super didSelectRow];
    
    @weakify(self);
    Class SimpleTableViewControllerClass = [self.sectionItem.tableViewBuilder classForType:TMTableViewBuilderClassTypeSimpleTableViewController];
    Class TMRadioOpenRowItemClass = [self.sectionItem.tableViewBuilder classForType:TMTableViewBuilderClassTypeOptionRowItem];
    
    UIViewController<TMSimpleTableViewController> *simpleTableViewController = [[SimpleTableViewControllerClass alloc] init];
    TMSectionItem *sectionItem = [TMSectionItem new];
    [simpleTableViewController.tableViewBuilder addSectionItem:sectionItem];
    for (TMRadioRowItemSelectionModel *model in self.selectionModelList) {
        TMRowItem<TMRadioOptionRow> *rowItem = [TMRadioOpenRowItemClass new];
        
        [sectionItem addRowItem:rowItem];
        
        rowItem.model = model;
        if (self.selectedIndex && ([self.selectedIndex integerValue] == [self.selectionModelList indexOfObject:model])) {
            rowItem.selected = YES;
        }
        else {
            rowItem.selected = NO;
        }
        @weakify(simpleTableViewController);
        [rowItem setDidSelectRowHandler:^(TMRadioOptionRowItem *rowItem) {
            @strongify(self);
            @strongify(simpleTableViewController);
            self.selectedIndex = @([self.selectionModelList indexOfObject:rowItem.model]);
            [simpleTableViewController.navigationController popViewControllerAnimated:YES];
            
            if (self.didChooseOptionHandler) {
                self.didChooseOptionHandler(self, rowItem);
            }
        }];
    }
    
    simpleTableViewController.viewDidLoadCompletionHandler = ^(UITableViewController<TMSimpleTableViewController> *tableViewController) {
        @strongify(self);
        if (self.viewDidLoadForOptionViewController) {
            self.viewDidLoadForOptionViewController(tableViewController, self);
        }
    };
    
    if (!self.presentingViewController) {
        DDLogError(@"preseting view controller is not set");
    }
    
    if (!self.presentingViewController.navigationController) {
        DDLogError(@"presenting view controller does not have a navigation controller");
    }
    [self.presentingViewController.navigationController pushViewController:simpleTableViewController animated:YES];
}

- (NSString *)selectedText {
    if (!self.selectedIndex) {
        return self.textForNoSlection;
    }
    TMRadioRowItemSelectionModel *model = self.selectionModelList[self.selectedIndex.integerValue];
    return model.text;
}

+ (NSSet *)keyPathsForValuesAffectingSelectedText {
    return [NSSet setWithObjects:@keypath(TMRadioRowItem.new, selectedIndex), nil];
}

- (id)copyWithZone:(NSZone *)zone {
    TMRadioRowItem *rowItem = [super copyWithZone:zone];
    
    [rowItem setSelectionModelList:self.selectionModelList];
    [rowItem setSelectedIndex:self.selectedIndex];
    [rowItem setTextForNoSlection:self.textForNoSlection];
    [rowItem setDidChooseOptionHandler:self.didChooseOptionHandler];
    [rowItem setViewDidLoadForOptionViewController:self.viewDidLoadForOptionViewController];
 
    return rowItem;
}
@end


@implementation TMRadioRowItemSelectionModel

- (instancetype)initWithText:(NSString *)text context:(id)context {
    self = [super init];
    if (self) {
        self.text = text;
        self.context = context;
    }
    
    return self;
}

@end