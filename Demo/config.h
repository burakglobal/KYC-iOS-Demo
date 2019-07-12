//
//  config.h
//  Sum&SubstanceDemo
//
//  Created by Sergey Kokunov on 10/06/2019.
//  Copyright © 2019 Sum & Substance. All rights reserved.
//

#if __has_include("Env")
    #import "Env"
#endif

#if ENV_PROD
    /// Production environment
    static NSString *const restBaseUrl = @"https://api.sumsub.com";
    static NSString *const kycBaseUrl = @"msdk.sumsub.com";
#else
    /// Testing environment
    static NSString *const restBaseUrl = @"https://test-api.sumsub.com";
    static NSString *const kycBaseUrl = @"test-msdk2.sumsub.com";
#endif

static NSString *const restLoginRequestPath = @"/resources/auth/login";
static NSString *const restCreateApplicantRequestPath = @"/resources/applicants";
