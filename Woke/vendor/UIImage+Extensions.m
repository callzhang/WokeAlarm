//
//  UIImage+Extensions.m
//  HelpMeChoose
//
//  Created by Yifan Cai on 11/27/12.
//  Copyright (c) 2012 Nanaimo Studio. All rights reserved.
//

#import "UIImage+Extensions.h"

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180/M_PI;};

@implementation UIImage (Extensions)

+ (UIImage *)imageWithColor:(UIColor *)color {
    UIImage *image = nil;
    @try {
        CGRect rect = CGRectMake(0, 0, 1, 1);
        // Create a 1 by 1 pixel context
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
        [color setFill];
        UIRectFill(rect);   // Fill it with your color
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
    }
    @catch (NSException *exception) {
        NSLog(@"Got Exception:%@", exception);
        image = nil;
    }
    @finally {
        return image;
    }
}


-(UIImage *)imageAtRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage* subImage = [UIImage imageWithCGImage: imageRef];
    CGImageRelease(imageRef);
    
    return subImage;
}

- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize {
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    // this is actually the interesting part:
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");
    
    return newImage ;
}

- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize {
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        
        if (widthFactor < heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor > heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");
    
    return newImage ;
}

- (UIImage *)imageByScalingProportionallyToMaxSize:(CGSize)targetSize
{
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        if (scaledHeight > targetHeight) {
            scaledHeight = targetHeight;
        }
        if (scaledWidth > targetWidth) {
            scaledWidth = targetWidth;
        }
    }
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(CGSizeMake(scaledWidth, scaledHeight));
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");
    
    return newImage ;
}

- (UIImage *)imageByScalingToSize:(CGSize)targetSize {
    
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    //   CGSize imageSize = sourceImage.size;
    //   CGFloat width = imageSize.width;
    //   CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    //   CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");
    
    return newImage ;
}

- (UIImage *)imageRotatedByRadians:(CGFloat)radians
{
    return [self imageRotatedByDegrees:RadiansToDegrees(radians)];
}

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees
{
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize
{
    UIImage *newImage = nil;
    @try {
        UIImage *sourceImage = self;
        CGSize imageSize = sourceImage.size;
        CGFloat width = imageSize.width;
        CGFloat height = imageSize.height;
        CGFloat targetWidth = targetSize.width;
        CGFloat targetHeight = targetSize.height;
        CGFloat scaleFactor = 0.0;
        CGFloat scaledWidth = targetWidth;
        CGFloat scaledHeight = targetHeight;
        CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
        
        if (CGSizeEqualToSize(imageSize, targetSize) == NO)
        {
            CGFloat widthFactor = targetWidth / width;
            CGFloat heightFactor = targetHeight / height;
            
            if (widthFactor > heightFactor)
            {
                scaleFactor = widthFactor; // scale to fit height
            }
            else
            {
                scaleFactor = heightFactor; // scale to fit width
            }
            
            scaledWidth  = width * scaleFactor;
            scaledHeight = height * scaleFactor;
            
            // center the image
            if (widthFactor > heightFactor)
            {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            }
            else
            {
                if (widthFactor < heightFactor)
                {
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
                }
            }
        }
        
        //    UIGraphicsBeginImageContext(targetSize); // this will crop
        UIGraphicsBeginImageContextWithOptions(targetSize, YES, 0);
        CGRect thumbnailRect = CGRectZero;
        thumbnailRect.origin = thumbnailPoint;
        thumbnailRect.size.width  = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        
        [sourceImage drawInRect:thumbnailRect];
        
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        if(newImage == nil)
        {
            NSLog(@"could not scale image");
        }
        
        //pop the context to get back to the default
        UIGraphicsEndImageContext();

    }
    @catch (NSException *exception) {
        NSLog(@"Got Exception:%@", exception);
        newImage = nil;
    }
    @finally {
        return newImage;
    }
}

@end
