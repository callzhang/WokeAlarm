//
//  EWMyFriendsViewController.h
//  Woke
//
//  Created by mq on 14-6-22.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EWPerson;
@interface EWFriendsViewController_old : UIViewController

-(id)initWithPerson:(EWPerson *)person cellSelect:(BOOL)cellSelect;
-(id)initWithPerson:(EWPerson *)person;
@property EWPerson *person;
@property (strong, nonatomic) IBOutlet UISegmentedControl *tabView;

@property (strong, nonatomic) IBOutlet UICollectionView *friendsCollectionView;
@property (strong, nonatomic) IBOutlet UITableView *friendsTableView;
- (IBAction)tabValueChange:(id)sender;
@end
