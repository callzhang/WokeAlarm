//
//  TMTableViewFetchedResultConfiguration.h
//  Pods
//
//  Created by Zitao Xiong on 6/1/15.
//
//

#import <Foundation/Foundation.h>
@class TMTableViewFetchedResultConfiguration;

@protocol TMRowItemProtocol;

@protocol TMTableViewFetchedResultConfigurationDelegate
- (void)configuration:(TMTableViewFetchedResultConfiguration*)configuration didCreateRowItem:(id)rowItem forMangagedObject:(id)mangedObject;
@end

/**
 * TMTableViewFetchedResultConfiguration is used to create rowItem
 * managedObjectClassName is used as key to lookup. it might changed
 */
@interface TMTableViewFetchedResultConfiguration : NSObject
@property (nonatomic, readonly) NSString *rowItemClassName;
@property (nonatomic, assign) Class<TMRowItemProtocol> rowItemClass;
@property (nonatomic, weak) NSObject<TMTableViewFetchedResultConfigurationDelegate> *delegate;
@property (nonatomic, copy) void (^didCreatedRowItemBlock)(TMTableViewFetchedResultConfiguration *configuration, id rowItem, id managedObject);
- (void)setDidCreatedRowItemBlock:(void (^)(TMTableViewFetchedResultConfiguration *configuration, id rowItem, id managedObject))didCreatedConfiguation;

- (instancetype)initWithRowItemClassName:(NSString *)rowItemClassName NS_DESIGNATED_INITIALIZER;
- (id)createdRowItemForMangedObject:(id)managedObject;
@end
