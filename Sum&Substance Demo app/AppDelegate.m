//
//  AppDelegate.m
//  Sum&Substance Demo app
//
//  Created by Alex on 10/01/2019.
//  Copyright © 2019 Sum & Substance. All rights reserved.
//

#import "AppDelegate.h"
#import "Coordinator.h"
#import "UIColor+AdditionalColors.h"
#import "Storage.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (![Storage.instance objectForKey:udLocale]) {
        [Storage.instance setObject:@"en_US" forKey:udLocale];
    }

    UINavigationController *const controller = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialViewController];
    controller.navigationBar.tintColor = UIColor.duskBlue;
    (self.window = UIWindow.new).rootViewController = controller;
    self.window.backgroundColor = UIColor.whiteColor;
    [self.window makeKeyAndVisible];
    [Coordinator createInstanceWith:controller];

    return YES;
}

@end
