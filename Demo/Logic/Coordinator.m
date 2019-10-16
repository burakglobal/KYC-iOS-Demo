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
#import <SumSubstanceKYC_Liveness3D/SSLiveness3D.h>

#import "config.h"

@interface Coordinator () <UIAdaptivePresentationControllerDelegate>

@property (nonatomic, strong) RKObjectManager *rest;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UIViewController *loginVC;
@property (nonatomic, strong) UIViewController *selectionVC;
@property (nonatomic, strong) UIViewController *loadingVC;

@property (nonatomic) NSString *applicantID;
@property (nonatomic) NSString *token;
@property (nonatomic) NSString *locale;

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

- (void)loginWith:(NSString *)login password:(NSString *)password onSuccess:(void(^)(void))onSuccess onFailure:(void(^)(NSError *error))onFailure {
    
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
                      if (onSuccess) onSuccess();
                  }
                  failure:^(RKObjectRequestOperation *operation, NSError *error) {
                      [Storage.instance setObject:nil forKey:udPassword];
                      if (onFailure) onFailure(error);
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

- (void)refreshToken {
    
    [self getNewToken:^(NSError *error, NSString *token) {

        if (!error) {
            [SSEngine.instance setRefreshToken:token];
        } else {
            [SSEngine.instance shutdown];
        }
    }];
}

- (void)getNewToken:(void(^)(NSError *error, NSString *token))onComplete {
    
    __weak typeof(self) weakSelf = self;
    
    NSString *login = [Storage.instance objectForKey:udLogin];
    NSString *password = [Storage.instance objectForKey:udPassword];
    
    [self loginWith:login password:password onSuccess:^{
        
        return onComplete ? onComplete(nil, weakSelf.token) : nil;
        
    } onFailure:^(NSError *error) {
        
        [weakSelf showAlertWithTitle:@"Unable to obtain new token"
                             message:error.localizedDescription
                               onTap:^(BOOL shouldRetry)
         {
             if (shouldRetry) {
                 [weakSelf getNewToken:onComplete];
             } else {
                 return onComplete ? onComplete(error, nil) : nil;
             }
         }];
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
    NSString *baseUrl = kycBaseUrl;
    NSString *applicantId = self.applicantId;
    NSString *token = self.token;
    NSString *locale = self.locale;
    NSString *supportEmail = @"support@sumsub.com";
    
    SSEngine *engine = [SSFacade setupForApplicant:applicantId
                                         withToken:token
                                            locale:locale
                                      supportEmail:supportEmail
                                           baseUrl:baseUrl
                                       colorConfig:nil
                                       imageConfig:nil];

    [engine connectWithExpirationHandler:^{
        
        // Handle token expiration
        NSLog(@"Coordinator: token is expired");
        
        [Coordinator.instance refreshToken];
        
    } verificationResultHandler:^(bool verified) {
        
        // Handle verification result
        NSLog(@"Coordinator: verification is done (verified=%@)", @(verified));
    }];
    
    UINavigationController *chatVC = [SSFacade getChatControllerWithAttributedTitle:self.attributedTitleForChat];
    
    // iOS 13 option 1:
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        chatVC.modalPresentationStyle = UIModalPresentationFullScreen;
    }

//    // iOS 13 option 2:
//    chatVC.presentationController.delegate = self;
    
    [self.navigationController presentViewController:chatVC
                                            animated:true
                                          completion:^{
                                              [self removeLoadingScreenAnimated:false];
                                          }];
}

#pragma mark - <UIAdaptivePresentationControllerDelegate>

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController {
    
    [SSEngine.instance shutdown];
}

#pragma mark - Liveness

- (void)livenessCheck {
    
    NSString *baseUrl = kycBaseUrl;
    NSString *token = self.token;
    NSString *locale = self.locale;

    // Setup
    
    // Note: Text localization is based on Zoom.strings file
    //       that should be added into the host application,
    //       see Demo/Resources/Zoom.string for the example
    
    SSLiveness3D *liveness3D =
    [SSLiveness3D.alloc initWithBaseUrl:baseUrl
                                  token:token
                                 locale:locale
                 tokenExpirationHandler:^(void (^ _Nonnull completionHandler)(NSString * _Nullable))
     {
         NSLog(@"Coordinator: token is expired");
         
         // get new token then call completionHandler
         [self getNewToken:^(NSError *error, NSString *token) {
             
             completionHandler(token);
         }];
         
     } completionHandler:^(UIViewController * _Nonnull controller, SSLiveness3DStatus status) {
         
         NSLog(@"Coordinator: Liveness3D completes with status: %@", [SSLiveness3D descriptionForStatus:status]);
         
         // if (status == SSLiveness3DStatus_CameraPermissionDenied) {
         //     [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
         // }
         
         [controller dismissViewControllerAnimated:YES completion:nil];
     }];

//    // Optional image customization
//
//    liveness3D.imageHandler = ^UIImage * _Nullable(NSString * _Nonnull key) {
//
//        if ([key isEqualToString:@"liveness-logo"]) {
//            return [UIImage imageNamed:@"AppIcon"];
//        } else {
//            return nil;
//        }
//    };
//
//    // Optional color theme
//    liveness3D.theme = ...

    // Create and display view controller
    
    UIViewController *vc = [liveness3D getController];
    
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Storage

- (NSString *)applicantId {
    return [Storage.instance objectForKey:udApplicant];
}

- (NSString *)token {
    return [Storage.instance objectForKey:udToken];
}

- (NSString *)locale {
    return [Storage.instance objectForKey:udLocale];
}

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

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message onTap:(void(^)(BOOL shouldRetry))onTap {
    
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:
     [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
        if (onTap) onTap(NO);
        [alert dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [alert addAction:
     [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        if (onTap) onTap(YES);
        [alert dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    UIViewController *controller = UIApplication.sharedApplication.keyWindow.rootViewController;
    while (controller.presentedViewController) controller = controller.presentedViewController;
    [controller presentViewController:alert animated:YES completion:nil];
}

@end
