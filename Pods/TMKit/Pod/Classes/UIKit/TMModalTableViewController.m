//
//  TMModalTableViewController.m
//  Pods
//
//  Created by Zitao Xiong on 5/4/15.
//
//

#import "TMModalTableViewController.h"

@interface TMModalTableViewController ()

@end

@implementation TMModalTableViewController
+ (UINavigationController *)viewControllerContainedInNavigationController {
    TMModalTableViewController *vc = [[self alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    vc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:vc action:@selector(onDoneBarButtonItem:)];
    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:vc action:@selector(onCancelBarButtonItem:)];
    
    return nav;
}

- (void)onDoneBarButtonItem:(id)sender {
    if (self.canSaveBlock) {
        if (self.canSaveBlock(self)) {
            [self dismissViewControllerAnimated:YES completion:^{
                if (self.didSaveBlock) {
                    self.didSaveBlock(self);
                }
            }];
        }
    }
    else {
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.didSaveBlock) {
                self.didSaveBlock(self);
            }
        }];
    }
}

- (void)onCancelBarButtonItem:(id)sender {
    if (self.canCancelBlock) {
        if (self.canCancelBlock(self)) {
            [self dismissViewControllerAnimated:YES completion:^{
                if (self.didCancelBlock) {
                    self.didCancelBlock(self);
                }
            }];
        }
    }
    else {
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.didCancelBlock) {
                self.didCancelBlock(self);
            }
        }];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
@end
