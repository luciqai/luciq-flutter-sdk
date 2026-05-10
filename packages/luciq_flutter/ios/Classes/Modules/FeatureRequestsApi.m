#import "LuciqSDK/LuciqSDK.h"
#import "FeatureRequestsApi.h"
#import "ArgsRegistry.h"
#import "../Util/LCQRunCatching.h"

extern void InitFeatureRequestsApi(id<FlutterBinaryMessenger> messenger) {
    FeatureRequestsApi *api = [[FeatureRequestsApi alloc] init];
    FeatureRequestsHostApiSetup(messenger, api);
}

@implementation FeatureRequestsApi

- (void)showWithError:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"FeatureRequestsApi.show", ^{
        [LCQFeatureRequests show];
    });
}

- (void)setEmailFieldRequiredIsRequired:(NSNumber *)isRequired actionTypes:(NSArray<NSString *> *)actionTypes error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"FeatureRequestsApi.setEmailFieldRequired", ^{
        LCQAction resolvedTypes = 0;
        for (NSString *type in actionTypes) {
            resolvedTypes |= (ArgsRegistry.actionTypes[type]).integerValue;
        }
        [LCQFeatureRequests setEmailFieldRequired:[isRequired boolValue] forAction:resolvedTypes];
    });
}

@end
