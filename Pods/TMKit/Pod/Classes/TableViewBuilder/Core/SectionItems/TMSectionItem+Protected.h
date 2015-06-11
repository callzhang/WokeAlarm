//
//  TMSectionItem+Protected.h
//  TMKit
//
//  Created by Zitao Xiong on 3/25/15.
//  Copyright (c) 2015 Nanaimostudio. All rights reserved.
//

#import "TMSectionItem.h"
#import "TMSectionItemRowDataSource.h"

@class TMTableViewBuilder;

@interface TMSectionItem ()
@property (nonatomic, readwrite, weak) TMTableViewBuilder *tableViewBuilder;
@property (nonatomic, assign) TMSectionItemType type;
@property (nonatomic, strong) NSObject<TMSectionItemRowDataSource> *rowDataSource;
@end
