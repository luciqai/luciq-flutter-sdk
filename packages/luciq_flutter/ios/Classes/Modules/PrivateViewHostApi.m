//
//  PrivateViewHostApi.m
//  luciq_flutter
//
//  Created by Ahmed alaa on 02/11/2024.
//

#import "PrivateViewHostApi.h"
#import "luciq_flutter/LuciqApi.h"

extern void InitPrivateViewHostApi(id<FlutterBinaryMessenger> _Nonnull messenger, PrivateViewApi * _Nonnull privateViewApi) {
    PrivateViewHostApi *api = [[PrivateViewHostApi alloc] init];
    api.privateViewApi = privateViewApi;
    LuciqPrivateViewHostApiSetup(messenger, api);
}

@implementation PrivateViewHostApi


- (void)initWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    NSLog(@" LCQ_FLUTTER:Init With Private views");
    [LuciqApi setScreenshotMaskingHandler:^(UIImage * _Nonnull screenshot, void (^ _Nonnull completion)(UIImage * _Nullable)) {
        
        NSLog(@"LCQ_FLUTTER:Private views CALLback called");

        
           [self.privateViewApi mask:screenshot completion:^(UIImage * _Nonnull maskedImage) {
             if (maskedImage != nil) {
                 NSLog(@"LCQ_FLUTTER:Private views CALLback compeleted");

                 completion(maskedImage);
                }
           }];
       }];
}

@end
