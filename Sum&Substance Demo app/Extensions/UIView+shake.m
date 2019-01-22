//
// Created by Alex on 2019-01-11.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "UIView+shake.h"


@implementation UIView (shake)
- (void)shake {
    self.transform = CGAffineTransformMakeTranslation(7, 0);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    [UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:.15 initialSpringVelocity:7.f
                        options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.transform = CGAffineTransformIdentity;
            }        completion:nil];
}
@end