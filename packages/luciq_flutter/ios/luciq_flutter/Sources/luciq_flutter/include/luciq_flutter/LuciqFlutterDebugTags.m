//
//  LuciqFlutterDebugTags.m
//  luciq_flutter
//

#import "LuciqFlutterDebugTags.h"

@implementation LuciqFlutterDebugTags
+ (NSString *)core               { return @"LCQ-Flutter-iOS-CORE:"; }
+ (NSString *)screenTracking     { return @"LCQ-Flutter-iOS-SCREEN:"; }
+ (NSString *)apmScreenLoading   { return @"LCQ-Flutter-iOS-APM-SL:"; }
+ (NSString *)apmScreenRendering { return @"LCQ-Flutter-iOS-APM-SR:"; }
+ (NSString *)apmUITrace         { return @"LCQ-Flutter-iOS-APM-UI:"; }
+ (NSString *)apmAppLaunch       { return @"LCQ-Flutter-iOS-APM-LAUNCH:"; }
+ (NSString *)apmCustomSpan      { return @"LCQ-Flutter-iOS-APM-SPAN:"; }
+ (NSString *)apmFlow            { return @"LCQ-Flutter-iOS-APM-FLOW:"; }
+ (NSString *)apmNetwork         { return @"LCQ-Flutter-iOS-APM-NET:"; }
+ (NSString *)bugReporting       { return @"LCQ-Flutter-iOS-BR:"; }
+ (NSString *)crashReporting     { return @"LCQ-Flutter-iOS-CRASH:"; }
+ (NSString *)sessionReplay      { return @"LCQ-Flutter-iOS-SR:"; }
+ (NSString *)privateView        { return @"LCQ-Flutter-iOS-PRIV:"; }
+ (NSString *)featureFlags       { return @"LCQ-Flutter-iOS-FF:"; }
+ (NSString *)network            { return @"LCQ-Flutter-iOS-NET:"; }
+ (NSString *)surveys            { return @"LCQ-Flutter-iOS-SUR:"; }
+ (NSString *)replies            { return @"LCQ-Flutter-iOS-REP:"; }
+ (NSString *)featureRequests    { return @"LCQ-Flutter-iOS-FR:"; }
+ (NSString *)appState           { return @"LCQ-Flutter-iOS-STATE:"; }
+ (NSString *)luciqLog           { return @"LCQ-Flutter-iOS-LOG:"; }
@end
