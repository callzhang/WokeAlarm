//
//  TMTableViewSearchResultsController.h
//  Pods
//
//  Created by Zitao Xiong on 6/4/15.
//
//

#import <UIKit/UIKit.h>
#import "TMSimpleTableViewController.h"
#import "TMSearchFilterring.h"

@interface TMTableViewSearchResultsController : UITableViewController<TMSimpleTableViewController, UISearchResultsUpdating, TMSearchFilterring>

@end
