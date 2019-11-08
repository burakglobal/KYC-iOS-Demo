//
// Created by Alex on 2019-01-11.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "LoginVC.h"
#import "RoundTextField.h"
#import "RoundButton.h"
#import "Coordinator.h"
#import "UIView+shake.h"
#import "Storage.h"
#import "UIColor+AdditionalColors.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface LoginVC ()

@property(strong, nonatomic) IBOutlet RoundTextField *loginTextField;
@property(strong, nonatomic) IBOutlet RoundTextField *passwordTextField;
@property(strong, nonatomic) IBOutlet RoundButton *loginButton;
@property(strong, nonatomic) IBOutlet UILabel *welcomeLabel;

@end

@implementation LoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.bgColor;
    
    [self setupWelcomeLabel];

    [[Storage.instance rac_channelTerminalForKey:udLogin] subscribe:self.loginTextField.rac_newTextChannel];
    [[Storage.instance rac_channelTerminalForKey:udPassword] subscribe:self.passwordTextField.rac_newTextChannel];

    self.passwordTextField.secureTextEntry = true;
}

- (void)setupWelcomeLabel {
    NSMutableAttributedString *string =
            [NSMutableAttributedString.alloc initWithString:@"Welcome,\n"
                                                 attributes:@{
                                                         NSFontAttributeName: [UIFont systemFontOfSize:36 weight:UIFontWeightMedium],
                                                 }];
    [string appendAttributedString:
            [NSAttributedString.alloc initWithString:@"log in to continue"
                                          attributes:@{
                                                  NSFontAttributeName: [UIFont systemFontOfSize:36 weight:UIFontWeightLight],
                                          }]];
    self.welcomeLabel.attributedText = string;
    self.welcomeLabel.textColor = UIColor.duskBlue;
}

- (IBAction)login {
    
    [Coordinator.instance loginWith:self.loginTextField.text password:self.passwordTextField.text onSuccess:^{
        
        [Coordinator.instance nextStep];
        
    } onFailure:^(NSError *error) {
        
        [self.passwordTextField shake];
    }];
}

@end
