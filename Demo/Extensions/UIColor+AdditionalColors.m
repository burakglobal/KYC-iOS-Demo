//
// Created by Alex on 2019-01-13.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "UIColor+AdditionalColors.h"
#import <SumSubstanceKYC/KYCColorConfig.h>

@implementation UIColor (AdditionalColors)

+ (KYCColorConfig *)kycColors {

    static dispatch_once_t onceToken;
    static KYCColorConfig *colorConfig;
    dispatch_once(&onceToken, ^{
        colorConfig = KYCColorConfig.new;
    });
    return colorConfig;
}

+ (instancetype)duskBlue {
    return [self _dynamicColorForLight:[UIColor colorWithRed:42 / 255.f green:51 / 255.f blue:143 / 255.f alpha:1]
                                  dark:UIColor.lightTextColor];
}

+ (instancetype)saladColor {
    return [self _dynamicColorForLight:[UIColor colorWithRed:28 / 255.f green:180 / 255.f blue:170 / 255.f alpha:1]
                                      dark:self.kycColors.acceptedMessageBubble];
}

+ (instancetype)bgColor {
    return self.kycColors.chatBackground;
}

+ (instancetype)navigationTintColor {
    return self.kycColors.navigationTint;
}

+ (instancetype)actionColor {
    return self.kycColors.actionButtonBackground;
}

+ (instancetype)actionHighlight {
    return self.kycColors.actionButtonHighlightedBackground;
}

+ (instancetype)actionTextDisabled {
    return [self _dynamicColorForLight:UIColor.lightTextColor dark:UIColor.grayColor];
}

#pragma mark - Helpers

+ (UIColor *)_dynamicColorForLight:(UIColor *)lightColor dark:(UIColor *)darkColor {
    
    if (@available(iOS 13.0, *)) {
        if (!lightColor || !darkColor) {
            return lightColor;
        }
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? darkColor : lightColor;
        }];
    } else {
        return lightColor;
    }
}

@end
