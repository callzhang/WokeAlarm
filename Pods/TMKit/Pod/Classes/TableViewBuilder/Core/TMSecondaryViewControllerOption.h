//
//  TMSecondaryViewControllerOption.h
//  Pods
//
//  Created by Zitao Xiong on 5/28/15.
//
//

#import <Foundation/Foundation.h>
#import "TMSimpleTableViewController.h"

typedef NS_ENUM(NSUInteger, TMSecondaryViewControllerPresentationStyle) {
    TMSecondaryViewControllerPresentationStyleShow, // -> showViewController
    //    TMSecondaryViewControllerPresentationStyleShowDetail, // -> showDetailViewController
    TMSecondaryViewControllerPresentationStylePresent, // -> presentViewController
    TMSecondaryViewControllerPresentationStylePush, // -> .navigationController:push:
};

@interface TMSecondaryViewControllerOption : NSObject
@property (nonatomic, assign) TMSecondaryViewControllerPresentationStyle presentationStyle;
@property (nonatomic, copy) void (^secondaryViewControllerViewDidLoadHandler) (UITableViewController<TMSimpleTableViewController> *vc, id rowItem);
@property (nonatomic, copy) void (^secondaryViewControllerViewWillDisappearHandler) (UITableViewController<TMSimpleTableViewController> *vc, id rowItem, TMSimpleViewControllerResultType rsultType);
@end
