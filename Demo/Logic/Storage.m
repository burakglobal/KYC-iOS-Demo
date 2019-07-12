//
// Created by Alex on 2019-01-11.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "Storage.h"

@implementation Storage

+ (instancetype)instance {
    return (Storage *) Storage.standardUserDefaults;
}

@end
