//
// Created by Alex on 2019-01-11.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSUserDefaults+RACSupport.h"

static NSString *const udToken = @"token";
static NSString *const udLogin = @"login";
static NSString *const udLocale = @"locale";
static NSString *const udPassword = @"password";
static NSString *const udApplicant = @"applicant";

@interface Storage : NSUserDefaults

+ (instancetype)instance;

@end
