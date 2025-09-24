// This header file defines Luciq methods that are called using selectors for test verification.

#import <LuciqSDK/LuciqSDK.h>

@interface Luciq (Test)
+ (void)setCurrentPlatform:(LCQPlatform)platform;
+ (void)reportCrashWithStackTrace:(NSDictionary*)stackTrace handled:(NSNumber*)handled;
@end
