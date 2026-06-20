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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureRequests] format:@"[FR.show] phase=enter"];
    [LCQFeatureRequests show];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureRequests] format:@"[FR.show] phase=exit"];
}

- (void)setEmailFieldRequiredIsRequired:(NSNumber *)isRequired actionTypes:(NSArray<NSString *> *)actionTypes error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureRequests] format:@"[FR.setEmailFieldRequired] phase=enter isRequired=%@ actionTypesCount=%lu", ([isRequired boolValue] ? @"true" : @"false"), (unsigned long)actionTypes.count];
    LCQAction resolvedTypes = 0;

    for (NSString *type in actionTypes) {
        NSNumber *mapped = ArgsRegistry.actionTypes[type];
        if (mapped == nil) {
            [LuciqFlutterLogger w:[LuciqFlutterDebugTags featureRequests] format:@"[FR.setEmailFieldRequired] phase=warn errorType=UnknownEnum actionType=%@", type];
            continue;
        }
        resolvedTypes |= mapped.integerValue;
    }

    [LCQFeatureRequests setEmailFieldRequired:[isRequired boolValue] forAction:resolvedTypes];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureRequests] format:@"[FR.setEmailFieldRequired] phase=exit"];
}

@end
