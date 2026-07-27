//
//  LuciqFlutterDebugTags.h
//  luciq_flutter
//
//  Native iOS debug-log tag inventory mirroring
//  lib/src/constants/debug_tags.dart.
//
//    Dart:    LCQ-Flutter-APM-FLOW:
//    iOS:     LCQ-Flutter-iOS-APM-FLOW:
//    Android: LCQ-Flutter-Android-APM-FLOW:
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LuciqFlutterDebugTags : NSObject

@property (class, nonatomic, readonly) NSString *core;
@property (class, nonatomic, readonly) NSString *screenTracking;
@property (class, nonatomic, readonly) NSString *apmScreenLoading;
@property (class, nonatomic, readonly) NSString *apmScreenRendering;
@property (class, nonatomic, readonly) NSString *apmUITrace;
@property (class, nonatomic, readonly) NSString *apmAppLaunch;
@property (class, nonatomic, readonly) NSString *apmCustomSpan;
@property (class, nonatomic, readonly) NSString *apmFlow;
@property (class, nonatomic, readonly) NSString *apmNetwork;
@property (class, nonatomic, readonly) NSString *bugReporting;
@property (class, nonatomic, readonly) NSString *crashReporting;
@property (class, nonatomic, readonly) NSString *sessionReplay;
@property (class, nonatomic, readonly) NSString *privateView;
@property (class, nonatomic, readonly) NSString *featureFlags;
@property (class, nonatomic, readonly) NSString *network;
@property (class, nonatomic, readonly) NSString *surveys;
@property (class, nonatomic, readonly) NSString *replies;
@property (class, nonatomic, readonly) NSString *featureRequests;
@property (class, nonatomic, readonly) NSString *appState;
@property (class, nonatomic, readonly) NSString *luciqLog;

@end

NS_ASSUME_NONNULL_END
