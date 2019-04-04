//
// Created by Alex on 2019-01-10.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "RoundTextField.h"


@implementation RoundTextField


- (void)awakeFromNib {
    [super awakeFromNib];
    self.clipsToBounds = true;
    self.font = [UIFont systemFontOfSize:18 weight:UIFontWeightLight];
}

// Placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {
    CGRect rect = [super textRectForBounds:bounds];
    return [self insetForRect:rect];

}

// Text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    CGRect rect = [super editingRectForBounds:bounds];
    return [self insetForRect:rect];

}

- (CGRect)insetForRect:(CGRect)rect {
    UIEdgeInsets insets = UIEdgeInsetsMake(20, 28, 18, 28);
    return UIEdgeInsetsInsetRect(rect, insets);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = self.frame.size.height / 2;

}

@end