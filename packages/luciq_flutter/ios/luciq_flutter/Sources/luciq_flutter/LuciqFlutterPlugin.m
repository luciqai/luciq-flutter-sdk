#import "LuciqFlutterPlugin.h"

#import "ApmApi.h"
#import "BugReportingApi.h"
#import "CrashReportingApi.h"
#import "FeatureRequestsApi.h"
#import "LuciqApi.h"
#import "LuciqLogApi.h"
#import "RepliesApi.h"
#import "SessionReplayApi.h"
#import "SurveysApi.h"
#import "PrivateViewApi.h"
#import "PrivateViewHostApi.h"

@implementation LuciqFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    InitApmApi([registrar messenger]);
    InitBugReportingApi([registrar messenger]);
    InitCrashReportingApi([registrar messenger]);
    InitFeatureRequestsApi([registrar messenger]);
    InitLuciqApi([registrar messenger], registrar);
    InitLuciqLogApi([registrar messenger]);
    InitRepliesApi([registrar messenger]);
    InitSessionReplayApi([registrar messenger]);
    InitSurveysApi([registrar messenger]);
    PrivateViewApi* privateViewApi = InitPrivateViewApi([registrar messenger],registrar);
    InitPrivateViewApi([registrar messenger], registrar);
    InitPrivateViewHostApi([registrar messenger], privateViewApi);
    // Set as the engine registers, before any of its FlutterViewControllers appear: the SDK resolves a
    // host's engine when the host comes on top, and a native app may register FlutterViewController as
    // a host before Dart calls attachToNativeApp. The SDK consults it only for registered hosts, so an
    // app that registers none is unaffected.
    [LuciqApi registerFlutterSourceResolver];
}

@end
