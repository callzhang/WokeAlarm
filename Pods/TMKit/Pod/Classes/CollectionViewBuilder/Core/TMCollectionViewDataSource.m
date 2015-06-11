//
//  TMCollectionViewDataSource.m
//  Pods
//
//  Created by Zitao Xiong on 5/5/15.
//
//

#import "TMCollectionViewDataSource.h"
#import "TMCollectionSectionItem.h"
#import "TMCollectionViewBuilder.h"
#import "TMCollectionItem.h"
@interface TMCollectionViewDataSource()
@end

@implementation TMCollectionViewDataSource
- (instancetype)initWithCollectionViewBuilder:(TMCollectionViewBuilder *)builder {
    self = [super init];
    if (self) {
        self.collectionViewBuilder = builder;
    }
    return self;
}
//@required

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    TMCollectionSectionItem *sectionItem = [self.collectionViewBuilder objectInMutableSectionItemsAtIndex:section];
    return [sectionItem countOfCollectionItems];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TMCollectionItem *item = [self.collectionViewBuilder itemAtIndexPath:indexPath];
    return [item cellForItem];
}

//@optional

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.collectionViewBuilder countOfMutableSectionItems];
}

// The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
//    
//}
@end
