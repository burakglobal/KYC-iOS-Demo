//
// Created by Alex on 2019-01-10.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "RoundButton.h"
#import "UIColor+AdditionalColors.h"
#import "UIImage+Mask.h"

@interface RoundButton ()
@property (nonatomic) UIColor *bgColor;
@property (nonatomic) UIColor *highlightBgColor;
@end;

@implementation RoundButton

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
            [self applyStyle];
        }
    }
}

- (void)setup {
    self.bgColor = UIColor.actionColor;
    self.highlightBgColor = UIColor.actionHighlight;
    
    self.titleLabel.font = [UIFont systemFontOfSize:20];
    const int shadowOffset = 14;
    self.contentEdgeInsets = UIEdgeInsetsMake(17, 0, 19 + shadowOffset, 0);
    
    [self applyStyle];
}

- (void)setBgColor:(UIColor *)bgColor highlightBgColor:(UIColor *)highlightBgColor {
    self.bgColor = bgColor;
    self.highlightBgColor = highlightBgColor;
    
    [self applyStyle];
}

- (void)applyStyle {
    
    [self setBackgroundImage:[[UIImage imageNamed:@"buttonBackground"] maskedImageWithColor:self.bgColor].resizableBubble
                    forState:UIControlStateNormal];
    [self setBackgroundImage:[[UIImage imageNamed:@"buttonPressed"] maskedImageWithColor:self.highlightBgColor].resizableBubble
                    forState:UIControlStateHighlighted];
    
}

@end
