//
// Created by Alex on 2019-01-11.
// Copyright (c) 2019 Sum & Substance. All rights reserved.
//

#import "SelectionVC.h"
#import "RoundButton.h"
#import "Storage.h"
#import "Coordinator.h"
#import "RoundTextField.h"
#import "UIColor+AdditionalColors.h"
#import "UIImage+Mask.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface SelectionVC () <UITextFieldDelegate>

@property(strong, nonatomic) IBOutlet UILabel *promoLabel;
@property(strong, nonatomic) IBOutlet RoundButton *createNewButton;
@property(strong, nonatomic) IBOutlet RoundButton *existingButton;
@property(strong, nonatomic) IBOutlet RoundButton *faceMatchButton;
@property(strong, nonatomic) IBOutlet RoundTextField *localeTextField;

@end

@implementation SelectionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupPromoLabel];

    RAC(self.existingButton, enabled) =
            [[Storage.instance rac_channelTerminalForKey:udApplicant] map:^NSNumber *(NSString *value) {
                return @(value.length > 0);
            }];

    RAC(self.faceMatchButton, enabled) =
            [[Storage.instance rac_channelTerminalForKey:udApplicant] map:^NSNumber *(NSString *value) {
                return @(value.length > 0);
            }];
    
    [self.faceMatchButton setBackgroundImage:[[UIImage imageNamed:@"buttonBackground"]
                                              maskedImageWithColor:UIColor.saladColor].resizableBubble
                                    forState:UIControlStateNormal];
    [self.faceMatchButton setBackgroundImage:[[UIImage imageNamed:@"buttonPressed"]
                                              maskedImageWithColor:[UIColor.saladColor
                                                                    colorWithAlphaComponent:0.75]].resizableBubble
                                    forState:UIControlStateHighlighted];

    self.localeTextField.delegate = self;
    
    [[[Storage.instance rac_channelTerminalForKey:udLocale] map:^NSString *(NSString *li) {
        
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:li];
        return [[locale displayNameForKey:NSLocaleIdentifier value:locale.localeIdentifier] componentsSeparatedByString:@" "][0].capitalizedString;
        
    }] subscribe:self.localeTextField.rac_newTextChannel];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self selectLanguage:textField];
    return NO;
}

- (IBAction)selectLanguage:(UIView *)sender {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
    [self addActionIn:controller forLocale:@"en_US"];
    [self addActionIn:controller forLocale:@"ru_RU"];
    // [self addActionIn:controller forLocale:@"de_DE"];
    
    controller.popoverPresentationController.sourceView = sender;
    controller.popoverPresentationController.sourceRect = sender.bounds;
    
    [self presentViewController:controller animated:true completion:nil];
}

- (void)addActionIn:(UIAlertController *)controller forLocale:(NSString *const)localeKey {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:localeKey];
    NSString *title = [[locale displayNameForKey:NSLocaleIdentifier value:locale.localeIdentifier]
                       componentsSeparatedByString:@" "][0].capitalizedString;
    
    UIAlertAction *action = [UIAlertAction
                             actionWithTitle:title
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *action) {
                                 [controller dismissViewControllerAnimated:YES completion:nil];
                                 [Storage.instance setObject:localeKey forKey:udLocale];
                             }];
    
    [controller addAction:action];
}

- (void)setupPromoLabel {
    NSMutableAttributedString *string = [NSMutableAttributedString.alloc
                                         initWithString:@"The fastest way to onboard your customers"
                                         attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:36 weight:UIFontWeightLight]}];
    [string setAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:36 weight:UIFontWeightMedium]}
                    range:[string.string rangeOfString:@"fastest"]];
    self.promoLabel.attributedText = string;
}

- (IBAction)startNewCheck {
    [Coordinator.instance startNewCheck];
}

- (IBAction)continueCheck {
    [Coordinator.instance continueCheck];
}

- (IBAction)faceMatchCheck {
    [Coordinator.instance faceMatchCheck];
}

@end
