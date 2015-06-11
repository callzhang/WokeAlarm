//
//  TMCollectionViewDataSource.h
//  Pods
//
//  Created by Zitao Xiong on 5/5/15.
//
//

@import Foundation;
@import UIKit;


@class TMCollectionViewBuilder;
@interface TMCollectionViewDataSource : NSObject<UICollectionViewDataSource>
@property (nonatomic, weak) TMCollectionViewBuilder *collectionViewBuilder;
- (instancetype)initWithCollectionViewBuilder:(TMCollectionViewBuilder *)builder NS_DESIGNATED_INITIALIZER;
@end
