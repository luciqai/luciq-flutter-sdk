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
    InitLuciqApi([registrar messenger]);
    InitLuciqLogApi([registrar messenger]);
    InitRepliesApi([registrar messenger]);
    InitSessionReplayApi([registrar messenger]);
    InitSurveysApi([registrar messenger]);
    PrivateViewApi* privateViewApi = InitPrivateViewApi([registrar messenger],registrar);
    InitPrivateViewApi([registrar messenger], registrar);
    InitPrivateViewHostApi([registrar messenger], privateViewApi);
}

@end
