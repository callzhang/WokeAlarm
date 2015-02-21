//
//  EWBaseViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWBaseViewController.h"
#import "EWMainNavigationController.h"

@interface EWBaseViewController ()

@end

@implementation EWBaseViewController
- (void)addNavigationBarButtons{
    if ([self conformsToProtocol:@protocol(EWBaseViewNavigationBarButtonsDelegate)]) {
        EWBaseViewController<EWBaseViewNavigationBarButtonsDelegate> *controller = (EWBaseViewController<EWBaseViewNavigationBarButtonsDelegate> *)self;
        //not in navigation controller
        if ([controller respondsToSelector:@selector(close:)]) {
            UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:[ImagesCatalog backButton] style:UIBarButtonItemStyleDone target:controller action:@selector(close:)];
            controller.navigationItem.leftBarButtonItem = leftBtn;
        }
        
        if ([controller respondsToSelector:@selector(more:)]) {
            UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithImage:[ImagesCatalog moreButton] style:UIBarButtonItemStyleDone target:controller action:@selector(more:)];
            controller.navigationItem.rightBarButtonItem = rightBtn;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    //apply buttons to all controllers that comfirms to button delegate
    if ([segue.destinationViewController conformsToProtocol:@protocol(EWBaseViewNavigationBarButtonsDelegate)]) {
        [segue.destinationViewController addNavigationBarButtons];
    }
    
    // 2. All known destination controllers assigned to properties
    if ([self respondsToSelector:NSSelectorFromString(segue.identifier)]) {
        [self setValue:segue.destinationViewController forKey:segue.identifier];
    }
}

@end
