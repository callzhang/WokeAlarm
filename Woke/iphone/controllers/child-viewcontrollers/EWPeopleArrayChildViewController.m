//
//  EWPeopleArrayChildViewController.m
//  Woke
//
//  Created by Zitao Xiong on 1/11/15.
//  Copyright (c) 2015 wokealarm. All rights reserved.
//

#import "EWPeopleArrayChildViewController.h"
#import "EWPeopleArrayCollectionViewCell.h"

#define kMaxCellNumer 4

@interface EWPeopleArrayChildViewController ()<UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;

@end

@implementation EWPeopleArrayChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView reloadData];
    
    @weakify(self);
    [[RACObserve(self, people) distinctUntilChanged] subscribeNext:^(NSArray *people) {
        @strongify(self);
        if (people.count == 0) {
           self.bottomLabel.text = @"Someone will wake you up.";
        }
        else if (people.count == 1) {
            self.bottomLabel.text = @"1 person will wake you up.";
        }
        else {
            self.bottomLabel.text = [NSString stringWithFormat:@"%@ people will wake you up.", @(self.people.count)];
        }
        
        [self.collectionView reloadData];
        
        DDLogVerbose(@"reload collection view data: people: %@", self.people);
    }];
    
    self.view.backgroundColor = [UIColor clearColor];
}

#pragma mark - <UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.people.count > kMaxCellNumer) {
        return kMaxCellNumer;
    }
    else if (self.people.count == 0) {
        return 1;
    }
    else {
        return self.people.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EWPeopleArrayCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PeopleArrayChildViewIdentifier" forIndexPath:indexPath];
    if (self.people.count > kMaxCellNumer) {
        if (indexPath.row == kMaxCellNumer - 1) {
            [cell setNumberLabelText:[NSString stringWithFormat:@"+%@", @(self.people.count - kMaxCellNumer)]];
        }
        else {
            cell.person = self.people[indexPath.row];
        }
    }
    else if (self.people.count == 0) {
        [cell setNumberLabelText:@"?"];
    }
    else {
        cell.person = self.people[indexPath.row];
    }
    
    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    NSInteger cellCount = [collectionView.dataSource collectionView:collectionView numberOfItemsInSection:section];
    if( cellCount >0 )
    {
        CGFloat cellWidth = ((UICollectionViewFlowLayout*)collectionViewLayout).itemSize.width+((UICollectionViewFlowLayout*)collectionViewLayout).minimumInteritemSpacing;
        CGFloat totalCellWidth = cellWidth*cellCount;
        CGFloat contentWidth = collectionView.frame.size.width-collectionView.contentInset.left-collectionView.contentInset.right;
        if( totalCellWidth<contentWidth )
        {
            CGFloat padding = (contentWidth - totalCellWidth) / 2.0;
            return UIEdgeInsetsMake(0, padding, 0, padding);
        }
    }
    return UIEdgeInsetsZero;
}
@end