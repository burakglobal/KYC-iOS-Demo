//
// Created by Alex on 2019-01-11.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "Coordinator.h"
#import "Storage.h"
#import "LoginVC.h"
#import <RestKit/RestKit.h>
#import <UIKit/UIKit.h>
#import "UIViewController+StoryboardInstance.h"
#import "SelectionVC.h"
#import "LoadingVC.h"
#import <SumSubstanceKYC/SumSubstanceKYC.h>
#import <SumSubstanceKYC/KYCColorConfig.h>
#import <SumSubstanceKYC/KYCImageConfig.h>
#import "UIColor+AdditionalColors.h"

/// Production environment
// static NSString *const loginApiLink = @"https://api.sumsub.com";
// static NSString *const kycBaseUrl = @"msdk.sumsub.com";

/// Testing environment
static NSString *const loginApiLink = @"https://test-api.sumsub.com";
static NSString *const kycBaseUrl = @"test-msdk2.sumsub.com";

static NSString *const restLoginRequestPath = @"/resources/auth/login";
static NSString *const restCreateApplicantRequestPath = @"/resources/applicants";

@interface Coordinator ()
@property(nonatomic, strong) RKObjectManager *rest;
@property(nonatomic, strong) UINavigationController *navigationController;
@property(nonatomic, strong) UIViewController *loginVc;
@property(nonatomic, strong) UIViewController *selectionVC;
@property(nonatomic, strong) UIViewController *loadingVC;
@end

@implementation Coordinator

#pragma mark - Instance
static Coordinator *instance;

+ (instancetype)instance {
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addTitle:self.loginVc = LoginVC.createInstanceFromStoryboard];
        [self addTitle:self.loadingVC = LoadingVC.createInstanceFromStoryboard];
        [self addTitle:self.selectionVC = SelectionVC.createInstanceFromStoryboard];
        [self setupRest];
    }

    return self;
}

+ (void)createInstanceWith:(UINavigationController *const)controller {
    instance = Coordinator.new;
    instance.navigationController = controller;
    [instance nextStep];
}

- (void)addTitle:(UIViewController *const)controller {
    UILabel *label = UILabel.new;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.attributedText = Coordinator.getAttributedTitleForChat;
    controller.navigationItem.titleView = label;
}

#pragma mark - UI

- (void)nextStep {
    NSString *token = [Storage.instance stringForKey:udToken];
    if (!token) {
        [self.navigationController setViewControllers:@[self.loginVc] animated:true];
    } else {
        [self.navigationController setViewControllers:@[self.loginVc, self.selectionVC] animated:true];
    }
}

- (void)showLoadingScreen {
    [self.navigationController pushViewController:self.loadingVC animated:true];

}

- (void)removeLoadingScreenAnimated:(bool)animated {
    if ([self.navigationController.viewControllers containsObject:self.loadingVC]) {
        NSMutableArray *o = self.navigationController.viewControllers.mutableCopy;
        [o removeObject:self.loadingVC];
        [self.navigationController setViewControllers:o.copy animated:animated];
    }
}

#pragma mark - Rest

- (void)setupRest {
    self.rest = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:loginApiLink]];
    self.rest.requestSerializationMIMEType = RKMIMETypeJSON;
    [self addLoginMapping];
    [self addCreateApplicantMapping];
}

- (void)addLoginMapping {
    RKObjectMapping *const mapping = [RKObjectMapping requestMapping];
    [mapping addAttributeMappingsFromArray:@[@"status", @"payload"]];
    [self.rest addResponseDescriptor:[RKResponseDescriptor
            responseDescriptorWithMapping:mapping
                                   method:RKRequestMethodPOST
                              pathPattern:restLoginRequestPath
                                  keyPath:nil
                              statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
}

- (void)addCreateApplicantMapping {
    RKObjectMapping *const mapping = [RKObjectMapping requestMapping];
    [mapping addAttributeMappingsFromArray:@[@"id"]];
    [self.rest addResponseDescriptor:[RKResponseDescriptor
            responseDescriptorWithMapping:mapping
                                   method:RKRequestMethodPOST
                              pathPattern:restCreateApplicantRequestPath
                                  keyPath:nil
                              statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
}


- (void)loginWith:(NSString *)login password:(NSString *)password failureAnimation:(void (^)())failureAnimation {
    [self setAuthLogin:login password:password];
    [self.rest.HTTPClient setAuthorizationHeaderWithUsername:login password:password];
    [self.rest postObject:nil path:restLoginRequestPath parameters:@{@"ttlInSecs": @84400}
                  success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                      NSString *authToken = [mappingResult.firstObject valueForKey:@"payload"];
                      NSLog(@"authToken is %@", authToken);
                      [self setAuthToken:authToken];
                      [self nextStep];
                  }
                  failure:^(RKObjectRequestOperation *operation, NSError *error) {
                      [Storage.instance setObject:nil forKey:udPassword];
                      if (failureAnimation) failureAnimation();
                  }];
}

- (void)createNewApplicant:(void (^)())then {
    NSString *token = [Storage.instance stringForKey:udToken];
    [self.rest.HTTPClient setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", token]];
    [self.rest postObject:nil path:restCreateApplicantRequestPath
               parameters:@{
                       @"info": @{},
                       @"requiredIdDocs": @{
                               @"docSets": @[
                                       @{
                                               @"idDocSetType": @"IDENTITY",
                                               @"types": @[@"ID_CARD", @"PASSPORT", @"DRIVERS"],
                                               @"subTypes": @[@"FRONT_SIDE", @"BACK_SIDE"]
                                       },
                                       @{@"idDocSetType": @"SELFIE", @"types": @[@"SELFIE"]}
                               ],
                               @"includedCountries": @[],
                               @"excludedCountries": @[]
                       }
               }
                  success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                      NSString *applicant = [mappingResult.firstObject valueForKey:@"id"];
                      NSLog(@"new applicant %@", applicant);
                      [self setApplicant:applicant];
                      if (then) then();
                  }
                  failure:^(RKObjectRequestOperation *operation, NSError *error) {
                      [self invalidateAuthToken];
                      [self nextStep];
                  }];
}

#pragma mark - Storage

- (void)setApplicant:(NSString *)applicant {
    [Storage.instance setObject:applicant forKey:udApplicant];
}

- (void)invalidateAuthToken {
    [self setAuthToken:nil];
}

- (void)setAuthToken:(NSString *)token {
    [Storage.instance setObject:token forKey:udToken];
    [self.rest.HTTPClient setAuthorizationHeaderWithToken:token];
}

- (void)setAuthLogin:(NSString *)login password:(NSString *)password {
    [Storage.instance setObject:login forKey:udLogin];
    [Storage.instance setObject:password forKey:udPassword];
}

#pragma mark - KYC

- (void)startNewCheck {
    [self showLoadingScreen];
    [self createNewApplicant:^{
        [self startKYC];
    }];
}


- (void)continueCheck {
    [self startKYC];
}

- (void)startKYC {
    setenv("SS_DEBUG", "true", 1);
    NSString *applicantID = [Storage.instance objectForKey:udApplicant];
    NSString *locale = [Storage.instance objectForKey:udLocale];
    NSString *token = [Storage.instance objectForKey:udToken];
    SSEngine *engine = [SSFacade setupForApplicant:applicantID
                                         withToken:token
                                            locale:locale
                                      supportEmail:@"support@sumsub.com"
                                           baseUrl:kycBaseUrl
                                       colorConfig:nil
                                       imageConfig:nil];

    [engine connectWithExpirationHandler:^{
        /// Handle token expiration
        /// [SSEngine.instance setRefreshToken:newToken];
    }          verificationResultHandler:^(bool verified) {
        ///
    }];
    void (^ const block)(void) = ^(void) {
        [self.navigationController presentViewController:[SSFacade getChatControllerWithAttributedTitle:Coordinator.getAttributedTitleForChat]
                                                animated:true
                                              completion:^{
                                                  [self removeLoadingScreenAnimated:false];
                                              }];
    };
    CGFloat d = 0;
    if ([self.navigationController.viewControllers containsObject:self.loadingVC]) {d = 1.5;}
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (d * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}


+ (NSMutableAttributedString *)getAttributedTitleForChat {
    NSMutableAttributedString *string = [NSMutableAttributedString.alloc initWithString:@"Identity Verification\n" attributes:@{
            NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightMedium],
            NSForegroundColorAttributeName: UIColor.duskBlue,
    }];
    [string appendAttributedString:[NSAttributedString.alloc initWithString:@"Sum&Substance" attributes:@{
            NSFontAttributeName: [UIFont systemFontOfSize:11 weight:UIFontWeightMedium],
            NSForegroundColorAttributeName: UIColor.duskBlue,
    }]];
    return string;
}
@end
