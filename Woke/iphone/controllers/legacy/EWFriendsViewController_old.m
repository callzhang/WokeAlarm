//
//  EWMyFriendsViewController.m
//  Woke
//
//  Created by mq on 14-6-22.
//  Copyright (c) 2014年 Shens. All rights reserved.
//

#import "EWFriendsViewController_old.h"
#import "EWPerson.h"
#import "EWCollectionPersonCell.h"
#import "EWUIUtil.h"
#import "EWPersonManager.h"
#import "EWPersonViewController.h"
#import "UIView+Extend.h"
NSString * const tableViewCellId =@"MyFriendsTableViewCellId";
NSString * const collectViewCellId = @"friendsCollectionViewCellId";

@interface EWFriendsViewController_old ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
{
    NSArray *friendIDs;
    NSArray *mutualFriends;
}

@end

@implementation EWFriendsViewController_old

-(id)initWithPerson:(EWPerson *)person cellSelect:(BOOL)cellSelect
{
    self = [self initWithPerson:person];
    //self.cellSelect = cellSelect;
    return self;
}
-(id)initWithPerson:(EWPerson *)person
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.person = person;
        //self.cellSelect = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initData];
    [self initView];

    // Do any additional setup after loading the view from its nib.
}

#pragma mark - init

-(void)initData
{
    
    //NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    
    //_friendsTableView.delegate = self;
    //_friendsTableView.dataSource = self;
    _friendsCollectionView.delegate = self;
    _friendsCollectionView.dataSource = self;
    
    [self.view showLoopingWithTimeout:0];
    
    friendIDs = _person.cachedInfo[kCachedFriends];
    NSMutableSet *myFriendIDs = [NSMutableSet setWithArray:[EWPerson me].cachedInfo[kCachedFriends]];
    [myFriendIDs intersectSet:[NSSet setWithArray:friendIDs]];
    mutualFriends = [myFriendIDs allObjects];
    [_friendsCollectionView reloadData];
    [EWUIUtil dismissHUDinView:self.view];
    

}
-(void)initView
{
   
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackButton"] style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    [self.view bringSubviewToFront:self.tabView];
    self.title = @"Friends";
    [self.navigationItem.titleView addSubview:self.tabView];
    self.view.backgroundColor = [UIColor clearColor];
    _friendsCollectionView.backgroundColor = [UIColor clearColor];
    _friendsCollectionView.hidden = NO;
     UINib *nib = [UINib nibWithNibName:@"EWCollectionPersonCell" bundle:nil];
    [_friendsCollectionView registerNib:nib  forCellWithReuseIdentifier:collectViewCellId];
    _tabView.selectedSegmentIndex = 0;
    
    
    _friendsTableView.backgroundView = nil;
    _friendsTableView.backgroundColor = [UIColor clearColor];
    _friendsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //_friendsTableView.allowsSelection = _cellSelect;
    _friendsTableView.hidden = YES;
    [_friendsTableView registerNib:[UINib nibWithNibName:@"EWFriendsTableCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:tableViewCellId];
    
    //
    if ([friendIDs count]==1 || self.person.isMe) {
        _tabView.hidden = YES;
        [EWUIUtil applyAlphaGradientForView:_friendsCollectionView withEndPoints:@[@0.15]];
        _friendsCollectionView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
    }else{
        [EWUIUtil applyAlphaGradientForView:_friendsCollectionView withEndPoints:@[@0.25]];
        _friendsCollectionView.contentInset = UIEdgeInsetsMake(120, 0, 0, 0);
    }
   
}

-(void)close:(id)sender
{
//    [self.navigationController popViewControllerWithBlur];
    [self.navigationController popViewControllerAnimated:YES];

}



//#pragma mark - TableView
//-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    return 1;
//}
//
//-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return [mutualFriends count];
//}
//
//-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    EWFriendsTableCell *cell = [_friendsTableView dequeueReusableCellWithIdentifier:tableViewCellId];
//    EWPerson * myFriend = [friends objectAtIndex:indexPath.row];
//    [cell setupCellWithPerson:myFriend];
//    
//    return cell;
//}
//-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
////    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
//}
//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 60;
//}
//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    [self pushControllerWithArrayNumber:indexPath.row];
//
//   
//}


#pragma mark - CollectionView
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [friendIDs count];
    
}


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    EWCollectionPersonCell * cell = [_friendsCollectionView dequeueReusableCellWithReuseIdentifier:collectViewCellId forIndexPath:indexPath];
    cell.showName = YES;
    EWPerson * friend = [friendIDs objectAtIndex:indexPath.row];
    
    cell.person = friend;

//    cell.backgroundColor = [UIColor redColor];
   
    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(80, 100);
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 20, 5, 10);
}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self pushControllerWithArrayNumber:indexPath.row];
    
}

- (IBAction)tabValueChange:(UISegmentedControl *)sender {
    NSUInteger value =  [sender selectedSegmentIndex];
    switch (value) {
        case 0:
        {
            _friendsCollectionView.hidden = NO;
            _friendsTableView.hidden = YES;
            break;
        }
            
        case 1:
        {
            _friendsTableView.hidden = NO;
            _friendsCollectionView.hidden  = YES;
            break;
        }
        default:
            break;
    }
    [self.view bringSubviewToFront:self.tabView];
}
#pragma mark - help method
-(void)pushControllerWithArrayNumber:(NSInteger)number
{
    if ([self.navigationController.viewControllers count] <kMaxPersonNavigationConnt) {
        
        EWPerson * friend = [friendIDs objectAtIndex:number];
		EWPersonViewController *viewController = [[EWPersonViewController alloc] initWithNibName:nil bundle:nil];
		viewController.person = friend;
        [self.navigationController pushViewController:viewController animated:YES];
        
    }

}

@end