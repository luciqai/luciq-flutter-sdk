//
//  PrivateViewHostApi.m
//  luciq_flutter
//
//  Created by Ahmed alaa on 02/11/2024.
//

#import "PrivateViewHostApi.h"
#import "luciq_flutter/LuciqApi.h"
#import "../Util/LuciqFlutterLogger.h"
#import "../Util/LuciqFlutterDebugTags.h"

extern void InitPrivateViewHostApi(id<FlutterBinaryMessenger> _Nonnull messenger, PrivateViewApi * _Nonnull privateViewApi) {
    PrivateViewHostApi *api = [[PrivateViewHostApi alloc] init];
    api.privateViewApi = privateViewApi;
    LuciqPrivateViewHostApiSetup(messenger, api);
}

@implementation PrivateViewHostApi


- (void)initWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags privateView]
                   format:@"[PRIV.init] phase=enter"];
    [LuciqApi setScreenshotMaskingHandler:^(UIImage * _Nonnull screenshot, void (^ _Nonnull completion)(UIImage * _Nullable)) {
        [LuciqFlutterLogger d:[LuciqFlutterDebugTags privateView]
                       format:@"[PRIV.screenshotMaskingHandler] phase=enter"];

           [self.privateViewApi mask:screenshot completion:^(UIImage * _Nonnull maskedImage) {
             if (maskedImage != nil) {
                 completion(maskedImage);
                }
           }];
       }];
}

@end
