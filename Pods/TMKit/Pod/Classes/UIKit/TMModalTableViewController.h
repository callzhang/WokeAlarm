//
//  TMModalTableViewController.h
//  Pods
//
//  Created by Zitao Xiong on 5/4/15.
//
//

#import <UIKit/UIKit.h>

@interface TMModalTableViewController : UITableViewController
@property (nonatomic, copy) void (^didSaveBlock) (id viewController);
@property (nonatomic, copy) void (^didCancelBlock) (id viewController);
@property (nonatomic, copy) BOOL (^canSaveBlock) (id viewController);
@property (nonatomic, copy) BOOL (^canCancelBlock) (id viewController);

+ (UINavigationController *)viewControllerContainedInNavigationController;
@end
