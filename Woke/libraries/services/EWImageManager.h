//
//  EWImageStore.h
//  EarlyWorm
//
//  Created by Lei on 8/2/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWImageManager : NSObject

@property (nonatomic) NSMutableDictionary *allImages;

+ (EWImageManager *)sharedInstance;
- (void)setImage:(UIImage *)i forKey:(NSString *)key;
- (void)deleteImageForKey:(NSString *)key;
- (UIImage *)imageForKey:(NSString *)key;
- (NSString *)imagePathForKey:(NSString *)key;

@end
