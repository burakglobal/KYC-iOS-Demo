//
// Created by Alex on 2019-01-11.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "UIViewController+StoryboardInstance.h"

@implementation UIViewController (StoryboardInstance)

+ (instancetype)createInstanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil]
            instantiateViewControllerWithIdentifier:NSStringFromClass(self.class)];
}

@end
