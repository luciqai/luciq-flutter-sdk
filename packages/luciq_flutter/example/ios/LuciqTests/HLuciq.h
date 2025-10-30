#import <Foundation/Foundation.h>
#import "LuciqSDK/LuciqSDK.h"

@interface HLuciq : Luciq

// Track if setLocale was called
@property (class, nonatomic, assign) BOOL setLocaleCalled;
@property (class, nonatomic, assign) LCQLocale lastLocaleCalled;

// Enable/disable swizzling
+ (void)enableSwizzling;
+ (void)disableSwizzling;
+ (void)resetTracking;

+ (void)setLocale:(LCQLocale)locale;

@end
