//
//  EWBaseViewController.m
//  Woke
//
//  Created by Zitao Xiong on 12/11/2014.
//  Copyright (c) 2014 wokealarm. All rights reserved.
//

#import "EWBaseViewController.h"
#import "EWMainNavigationController.h"
#import "EWBackgroundView.h"

@interface EWBaseViewController ()

@end

@implementation EWBaseViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //add navigation buttons
    [self addNavigationBarButtons];
    
    //add background
    UIView *bg = [[EWBackgroundView alloc] initWithFrame:self.view.frame];
    self.backgroundView = bg;
    [self.view insertSubview:bg atIndex:0];
    NSArray *contraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[bg]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(bg)];
    //[self.constrants addObjectsFromArray:contraint];
    [self.view addConstraints:contraints];
    contraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[bg]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(bg)];
    //[self.constrants addObjectsFromArray:contraint];
    [self.view addConstraints:contraints];
}


- (void)addNavigationBarButtons{
    //not in navigation controller
    if ([self respondsToSelector:@selector(close:)]) {
        
        UIBarButtonItem *leftButton;
        
        if (self.navigationController) {
            if (self.navigationController.viewControllers.count > 1) {
                leftButton = [[UIBarButtonItem alloc] initWithImage:[ImagesCatalog backButton] style:UIBarButtonItemStyleDone target:self action:@selector(close:)];
                self.navigationItem.backBarButtonItem = leftButton;
            } else {
                //set menu button only if friends view controller is the only one in the stack
                leftButton = [self.mainNavigationController menuBarButtonItem];
                self.navigationItem.leftBarButtonItem = leftButton;
            }
        } else if (self.presentingViewController) {
            leftButton = [[UIBarButtonItem alloc] initWithImage:[ImagesCatalog wokeNavMenuClose] style:UIBarButtonItemStyleDone target:self action:@selector(close:)];
            self.navigationItem.leftBarButtonItem = leftButton;
        }
    }
    
    if ([self respondsToSelector:@selector(more:)]) {
        UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithImage:[ImagesCatalog moreButton] style:UIBarButtonItemStyleDone target:self action:@selector(more:)];
        self.navigationItem.rightBarButtonItem = rightBtn;
    }
}

- (EWMainNavigationController *)mainNavigationController {
    EWMainNavigationController *mainController = (EWMainNavigationController*)self.navigationController;
    if ([mainController isKindOfClass:[EWMainNavigationController class]]) {
        return mainController;
    }
    
    DDLogError(@"can't find EWMainNavigationController");
    DDLogError(@"nav controller is %@", self.navigationController);
    return nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    //All known destination controllers assigned to properties
    if ([self respondsToSelector:NSSelectorFromString(segue.identifier)]) {
        [self setValue:segue.destinationViewController forKey:segue.identifier];
    }
}

- (IBAction)close:(id)sender{
    //DDLogError(@"Please use sub-class implementation");
    if (self.presentingViewController || self.navigationController.viewControllers.firstObject == self){
        [self dismissViewControllerAnimated:YES completion:NULL];
    }else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

//- (IBAction)more:(id)sender {
//    DDLogError(@"Please use subclass to implement this method");
//}

@end
