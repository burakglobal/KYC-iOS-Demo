//
// Created by Alex on 2019-01-11.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "Coordinator.h"
#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>
#import "UIViewController+StoryboardInstance.h"
#import "UIColor+AdditionalColors.h"
#import "Storage.h"
#import "LoginVC.h"
#import "SelectionVC.h"
#import "LoadingVC.h"

#import <SumSubstanceKYC/SumSubstanceKYC.h>
#import <SumSubstanceKYC/KYCColorConfig.h>
#import <SumSubstanceKYC/KYCImageConfig.h>

#import "config.h"

@interface Coordinator ()

@property(nonatomic, strong) RKObjectManager *rest;
@property(nonatomic, strong) UINavigationController *navigationController;
@property(nonatomic, strong) UIViewController *loginVC;
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
#if DEBUG
        NSLog(@"Coordinator: has been instantiated with \nkycBaseUrl = %@\nrestBaseUrl = %@", kycBaseUrl, restBaseUrl);
#endif
        self.loginVC = [self configureVC:LoginVC.createInstanceFromStoryboard];
        self.loadingVC = [self configureVC:LoadingVC.createInstanceFromStoryboard];
        self.selectionVC = [self configureVC:SelectionVC.createInstanceFromStoryboard];
        [self setupRest];        
    }
    return self;
}

+ (void)createInstanceWith:(UINavigationController *const)controller {
    instance = Coordinator.new;
    instance.navigationController = controller;
    [instance nextStep];
}

#pragma mark - Rest

- (void)setupRest {
    self.rest = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:restBaseUrl]];
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

- (void)loginWith:(NSString *)login password:(NSString *)password failureAnimation:(void (^)(void))failureAnimation {
    
    [self setAuthLogin:login password:password];
    
    [self.rest.HTTPClient setAuthorizationHeaderWithUsername:login
                                                    password:password];
    [self.rest postObject:nil
                     path:restLoginRequestPath
               parameters:@{@"ttlInSecs": @84400}
                  success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                      NSString *authToken = [mappingResult.firstObject valueForKey:@"payload"];
#if DEBUG
                      NSLog(@"Coordinator: has obtained authToken\n%@", authToken);
#endif
                      [self setAuthToken:authToken];
                      [self nextStep];
                  }
                  failure:^(RKObjectRequestOperation *operation, NSError *error) {
                      [Storage.instance setObject:nil forKey:udPassword];
                      if (failureAnimation) failureAnimation();
                  }];
}

- (void)createNewApplicant:(void (^)(void))then {
    NSString *token = [Storage.instance stringForKey:udToken];
    
    [self.rest.HTTPClient setDefaultHeader:@"Authorization"
                                     value:[NSString stringWithFormat:@"Bearer %@", token]];
    [self.rest postObject:nil
                     path:restCreateApplicantRequestPath
               parameters:@{
                            @"info": @{},
                            @"requiredIdDocs": @{
                                    @"docSets": @[
                                            @{
                                                @"idDocSetType": @"IDENTITY",
                                                @"types": @[@"ID_CARD", @"PASSPORT", @"DRIVERS"],
                                                @"subTypes": @[@"FRONT_SIDE", @"BACK_SIDE"]
                                                },
                                            @{
                                                @"idDocSetType": @"SELFIE",
                                                @"types": @[@"SELFIE"],
                                                }
                                            ],
                                    @"includedCountries": @[],
                                    @"excludedCountries": @[]
                                    }
                            }
                  success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                      NSString *applicant = [mappingResult.firstObject valueForKey:@"id"];
#if DEBUG
                      NSLog(@"Coordinator: new applicant has been created\n%@", applicant);
#endif
                      [self setApplicant:applicant];
                      if (then) then();
                  }
                  failure:^(RKObjectRequestOperation *operation, NSError *error) {
                      [self invalidateAuthToken];
                      [self nextStep];
                  }];
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
#if DEBUG
    setenv("SS_DEBUG", "true", 1);
#endif
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
        // Handle token expiration
        NSLog(@"Coordinator: token is expired");
        // [SSEngine.instance setRefreshToken:newToken];
    } verificationResultHandler:^(bool verified) {
        // Handle verification result
        NSLog(@"Coordinator: verification is done (verified=%@)", @(verified));
    }];
    
    UINavigationController *chatVC = [SSFacade getChatControllerWithAttributedTitle:self.attributedTitleForChat];
    
    [self.navigationController presentViewController:chatVC
                                            animated:true
                                          completion:^{
                                              [self removeLoadingScreenAnimated:false];
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

#pragma mark - UI

- (UIViewController *)configureVC:(UIViewController *const)controller {
    UILabel *label = UILabel.new;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.attributedText = self.attributedTitleForChat;
    controller.navigationItem.titleView = label;
    return controller;
}

- (void)nextStep {
    NSString *token = [Storage.instance stringForKey:udToken];
    if (!token) {
        [self.navigationController setViewControllers:@[self.loginVC] animated:true];
    } else {
        [self.navigationController setViewControllers:@[self.loginVC, self.selectionVC] animated:true];
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

- (NSMutableAttributedString *)attributedTitleForChat {
    NSDictionary *attrs;
    NSMutableAttributedString *string = NSMutableAttributedString.new;
    {
        attrs = @{
                  NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightMedium],
                  NSForegroundColorAttributeName: UIColor.duskBlue,
                  };
        [string appendAttributedString:[NSMutableAttributedString.alloc
                                        initWithString:@"Identity Verification\n"
                                        attributes:attrs]];
    }
    {
        attrs = @{
                  NSFontAttributeName: [UIFont systemFontOfSize:11 weight:UIFontWeightMedium],
                  NSForegroundColorAttributeName: UIColor.duskBlue,
                  };
        [string appendAttributedString:[NSAttributedString.alloc
                                        initWithString:@"Sum&Substance"
                                        attributes:attrs]];
    }
    return string;
}

@end
