//
//  UIImage+Mask.m
//  SSDemo
//
//  Created by Sergey Kokunov on 12/09/2019.
//  Copyright © 2019 Sum & Substance. All rights reserved.
//

#import "UIImage+Mask.h"

@implementation UIImage (Mask)

- (UIImage *)maskedImageWithColor:(UIColor *)color {
    
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [self drawInRect:rect];
    CGContextSetFillColorWithColor(c, color.CGColor);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (UIImage *)resizableBubble {
    CGSize size = self.size;
    return [self resizableImageWithCapInsets:UIEdgeInsetsMake(.5 * size.height, .5 * size.width, .5 * size.height, .5 * size.width)];
}

@end
