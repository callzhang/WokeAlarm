//
//  EWProfileViewController.h
//  Woke
//
//  Created by Zitao Xiong on 2/1/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EWManagedNavigiationItemsViewController.h"

@interface EWProfileViewController : EWManagedNavigiationItemsViewController

@property (nonatomic, strong) EWPerson *person;
@end
