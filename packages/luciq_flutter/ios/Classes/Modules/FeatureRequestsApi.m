#import "LuciqSDK/LuciqSDK.h"
#import "FeatureRequestsApi.h"
#import "ArgsRegistry.h"
#import "../Util/LuciqFlutterLogger.h"
#import "../Util/LuciqFlutterDebugTags.h"

extern void InitFeatureRequestsApi(id<FlutterBinaryMessenger> messenger) {
    FeatureRequestsApi *api = [[FeatureRequestsApi alloc] init];
    FeatureRequestsHostApiSetup(messenger, api);
}

@implementation FeatureRequestsApi

- (void)showWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureRequests] format:@"[FR.show]"];
    [LCQFeatureRequests show];
}

- (void)setEmailFieldRequiredIsRequired:(NSNumber *)isRequired actionTypes:(NSArray<NSString *> *)actionTypes error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureRequests] format:@"[FR.setEmailFieldRequired] isRequired=%@ actionTypesCount=%lu", ([isRequired boolValue] ? @"YES" : @"NO"), (unsigned long)actionTypes.count];
    LCQAction resolvedTypes = 0;

    for (NSString *type in actionTypes) {
        resolvedTypes |= (ArgsRegistry.actionTypes[type]).integerValue;
    }

    [LCQFeatureRequests setEmailFieldRequired:[isRequired boolValue] forAction:resolvedTypes];
}

@end
