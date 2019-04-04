//
// Created by Alex on 2019-01-11.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RKObjectManager;
@class UINavigationController;
@class LoginVC;
@class SelectionVC;


@interface Coordinator : NSObject
+ (instancetype)instance;

- (void)loginWith:(NSString *)login password:(NSString *)password failureAnimation:(void (^)())animation;

+ (void)createInstanceWith:(UINavigationController *const)controller;

- (void)startNewCheck;

- (void)continueCheck;
@end