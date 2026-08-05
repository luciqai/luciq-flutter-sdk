//
//  LuciqFlutterLogger.h
//  luciq_flutter
//
//  Plugin-side logger that gates NSLog output on the same debugLogsLevel
//  the host app passes to Luciq.init(), so the native Flutter plugin
//  diagnostic logs do not leak in production builds when the Dart-side
//  LuciqLogger is silent.
//
//  Mirrors the level hierarchy in lib/src/utils/luciq_logger.dart:
//    Verbose > Debug > Error > None
//
//  LCQSDKDebugLogsLevel uses smaller-is-more-verbose (Verbose=1, Debug=2,
//  Error=3, None=4) — inverted vs Android.
//

#import <Foundation/Foundation.h>
#import <LuciqSDK/LuciqSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface LuciqFlutterLogger : NSObject

+ (void)setLevel:(LCQSDKDebugLogsLevel)level;
+ (LCQSDKDebugLogsLevel)level;

+ (void)d:(NSString *)tag format:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3);
+ (void)w:(NSString *)tag format:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3);
+ (void)e:(NSString *)tag format:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3);

+ (NSString *)redactURL:(nullable NSString *)url;

/// Returns a 4-hex-char correlation id (e.g. @"c7f3"). Mirrors
/// `CallId.next()` on the Dart side. Used for native-originated
/// callback fires so a single lifecycle can be reconstructed from
/// the logs of all three layers.
+ (NSString *)nextCallId;

@end

NS_ASSUME_NONNULL_END
