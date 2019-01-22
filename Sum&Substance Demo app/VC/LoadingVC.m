//
// Created by Alex on 2019-01-13.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "LoadingVC.h"


@implementation LoadingVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = true;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = false;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = true;
}


@end