//
//  PrivateViewHostApi.m
//  luciq_flutter
//
//  Created by Ahmed alaa on 02/11/2024.
//

#import "PrivateViewHostApi.h"
#import "luciq_flutter/LuciqApi.h"
#import "../Util/LCQRunCatching.h"

extern void InitPrivateViewHostApi(id<FlutterBinaryMessenger> _Nonnull messenger, PrivateViewApi * _Nonnull privateViewApi) {
    PrivateViewHostApi *api = [[PrivateViewHostApi alloc] init];
    api.privateViewApi = privateViewApi;
    LuciqPrivateViewHostApiSetup(messenger, api);
}

@implementation PrivateViewHostApi


- (void)initWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    LCQRunCatching(@"PrivateViewHostApi.init", ^{
        [LuciqApi setScreenshotMaskingHandler:^(UIImage * _Nonnull screenshot, void (^ _Nonnull completion)(UIImage * _Nullable)) {
            LCQRunCatching(@"PrivateViewHostApi.maskingHandler", ^{
                [self.privateViewApi mask:screenshot completion:^(UIImage * _Nonnull maskedImage) {
                    if (maskedImage != nil) {
                        completion(maskedImage);
                    }
                }];
            });
        }];
    });
}

@end
