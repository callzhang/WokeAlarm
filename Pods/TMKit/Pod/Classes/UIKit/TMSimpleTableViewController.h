//
//  TMSimpleTableViewController.h
//  Pods
//
//  Created by Zitao Xiong on 5/4/15.
//
//

#import <UIKit/UIKit.h>
#import "TMTableViewBuilder.h"

typedef NS_ENUM(NSUInteger, TMSimpleViewControllerResultType) {
    TMSimpleViewControllerResultTypeSucceed,
    TMSimpleViewControllerResultTypeCancelled,
};
//
//typedef NS_ENUM(NSUInteger, TMSimpleViewControllerPresentationStyle) {
//    TMSimpleViewControllerPresentationStyleShow, // -> showViewController
//    //    TMSimpleViewControllerPresentationStyleShowDetail, // -> showDetailViewController
//    TMSimpleViewControllerPresentationStylePresent, // -> presentViewController
//};
//@class TMSimpleViewControllerOption;



@protocol TMSimpleTableViewController
@required
@property (nonatomic, strong) TMTableViewBuilder *tableViewBuilder;

@optional
/**
 *  called after view did load
 */
@property (nonatomic, copy) void (^viewDidLoadCompletionHandler) (UITableViewController<TMSimpleTableViewController> *tableViewController);
/**
 *  called before view will disappear
 */
@property (nonatomic, copy) void (^viewWillDisappearCompletionHandler) (UITableViewController<TMSimpleTableViewController> *tableViewController, TMSimpleViewControllerResultType result);

//TODO: add result type 
@property (nonatomic, assign) TMSimpleViewControllerResultType resultType;
@end

//#pragma mark -
//@interface TMSimpleViewControllerOption : NSObject
//@property (nonatomic, assign) TMSimpleViewControllerPresentationStyle presentationStyle;
//@property (nonatomic, copy) void (^SimpleViewControllerViewDidLoadHandler) (UITableViewController<TMSimpleTableViewController> *vc, id rowItem);
//@property (nonatomic, copy) void (^SimpleViewControllerViewWillDisappearHandler) (UITableViewController<TMSimpleTableViewController> *vc, id rowItem, TMSimpleViewControllerResultType resultType);
//@end

#pragma mark -

@class TMRowItem;
@interface TMSimpleTableViewController : UITableViewController<TMSimpleTableViewController>
@end
