//
//  UIImage+Mask.h
//  SSDemo
//
//  Created by Sergey Kokunov on 12/09/2019.
//  Copyright © 2019 Sum & Substance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Mask)

- (UIImage *)maskedImageWithColor:(UIColor *)color;
- (UIImage *)resizableBubble;

@end

NS_ASSUME_NONNULL_END
