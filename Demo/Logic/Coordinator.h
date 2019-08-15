//
// Created by Alex on 2019-01-11.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UINavigationController;

@interface Coordinator : NSObject

+ (instancetype)instance;

+ (void)createInstanceWith:(UINavigationController *const)controller;

- (void)loginWith:(NSString *)login
         password:(NSString *)password
        onSuccess:(void(^)(void))onSuccess
        onFailure:(void(^)(NSError *error))onFailure;

- (void)nextStep;

- (void)startNewCheck;

- (void)continueCheck;

@end
