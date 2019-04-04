//
// Created by Alex on 2019-01-10.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "RoundButton.h"


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

- (void)setup {
    [self setBackgroundImage:[UIImage imageNamed:@"buttonBackground"] forState:UIControlStateNormal];
    [self setBackgroundImage:[UIImage imageNamed:@"buttonPressed"] forState:UIControlStateHighlighted];
    self.titleLabel.font = [UIFont systemFontOfSize:20];
    const int shadowOffset = 14;
    self.contentEdgeInsets = UIEdgeInsetsMake(17, 0, 19 + shadowOffset, 0);
}

@end