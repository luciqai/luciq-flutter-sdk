#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <Flutter/Flutter.h>
#import "LuciqSDK/LuciqSDK.h"
#import "LCQNetworkLogger+CP.h"
#import "LuciqApi.h"
#import "ArgsRegistry.h"
#import "../Util/LCQAPM+PrivateAPIs.h"

#import "../Util/Luciq+CP.h"
#import "../Util/LuciqFlutterLogger.h"
#import "../Util/LuciqFlutterDebugTags.h"
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0 blue:((float)(rgbValue & 0xFF)) / 255.0 alpha:((float)((rgbValue & 0xFF000000) >> 24)) / 255.0];

extern void InitLuciqApi(id<FlutterBinaryMessenger> messenger) {
    LuciqApi *api = [[LuciqApi alloc] init];
    LuciqHostApiSetup(messenger, api);
}

@implementation LuciqApi {
    NSMutableSet<NSString *> *_registeredFonts;
}

- (void)setEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    Luciq.enabled = [isEnabled boolValue];
}

- (nullable NSNumber *)isBuiltWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.isBuilt] phase=enter"];
    NSNumber *result = @(YES);
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.isBuilt] phase=exit resultPresent=true"];
    return result;
}


- (nullable NSNumber *)isEnabledWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.isEnabled] phase=enter"];
    NSNumber *result = @(Luciq.enabled);
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.isEnabled] phase=exit resultPresent=true"];
    return result;
}

- (void)initToken:(nonnull NSString *)token invocationEvents:(nonnull NSArray<NSString *> *)invocationEvents debugLogsLevel:(nonnull NSString *)debugLogsLevel appVariant:(nullable NSString *)appVariant error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    // Resolve the debug log level first so the gate is correct for any log
    // emitted during init (including the enter line itself). Defaulting to
    // Error on unknown input avoids quietly turning on max verbosity in prod
    // when the Dart side passes a string we don't recognize.
    NSNumber *resolvedLogLevelNumber = ArgsRegistry.sdkLogLevels[debugLogsLevel];
    LCQSDKDebugLogsLevel resolvedLogLevel = resolvedLogLevelNumber
        ? resolvedLogLevelNumber.integerValue
        : LCQSDKDebugLogsLevelError;
    [LuciqFlutterLogger setLevel:resolvedLogLevel];

    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core]
                   format:@"[Luciq.init] phase=enter tokenPresent=%@ invocationEventsCount=%lu debugLogsLevel=%ld appVariantPresent=%@",
        (token.length > 0 ? @"true" : @"false"),
        (unsigned long)invocationEvents.count,
        (long)resolvedLogLevel,
        (appVariant != nil ? @"true" : @"false")];

    if (ArgsRegistry.sdkLogLevels[debugLogsLevel] == nil) {
        [LuciqFlutterLogger w:[LuciqFlutterDebugTags core]
                       format:@"[Luciq.init] phase=warn errorType=UnknownEnum debugLogsLevel=%@", debugLogsLevel];
    }

    if(appVariant != nil){
        Luciq.appVariant = appVariant;
    }

    SEL setPrivateApiSEL = NSSelectorFromString(@"setCurrentPlatform:");
    if ([[Luciq class] respondsToSelector:setPrivateApiSEL]) {
        NSInteger *platformID = LCQPlatformFlutter;
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[Luciq class] methodSignatureForSelector:setPrivateApiSEL]];
        [inv setSelector:setPrivateApiSEL];
        [inv setTarget:[Luciq class]];
        [inv setArgument:&(platformID) atIndex:2];
        [inv invoke];
    }

    // Disable automatic capturing of native iOS network logs to avoid duplicate
    // logs of the same request when using a native network client like cupertino_http
    [LCQNetworkLogger disableAutomaticCapturingOfNetworkLogs];

    LCQInvocationEvent resolvedEvents = 0;
    for (NSString *event in invocationEvents) {
        if (ArgsRegistry.invocationEvents[event] == nil) {
            [LuciqFlutterLogger w:[LuciqFlutterDebugTags core]
                           format:@"[Luciq.init] phase=warn errorType=UnknownEnum event=%@", event];
        }
        resolvedEvents |= (ArgsRegistry.invocationEvents[event]).integerValue;
    }

    [Luciq setSdkDebugLogsLevel:resolvedLogLevel];
    [Luciq startWithToken:token invocationEvents:resolvedEvents];
    Luciq.sendEventsSwizzling = false;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.init] phase=exit"];
}

- (void)showWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.show] phase=enter"];
    [Luciq show];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.show] phase=exit"];
}

- (void)showWelcomeMessageWithModeMode:(NSString *)mode error:(FlutterError *_Nullable *_Nonnull)error {
    LCQWelcomeMessageMode resolvedMode = (ArgsRegistry.welcomeMessageStates[mode]).integerValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.showWelcomeMessageWithMode] phase=enter mode=%ld", (long)resolvedMode];
    if (ArgsRegistry.welcomeMessageStates[mode] == nil) {
        [LuciqFlutterLogger w:[LuciqFlutterDebugTags core]
                       format:@"[Luciq.showWelcomeMessageWithMode] phase=warn errorType=UnknownEnum mode=%@", mode];
    }
    [Luciq showWelcomeMessageWithMode:resolvedMode];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.showWelcomeMessageWithMode] phase=exit"];
}

- (void)identifyUserEmail:(NSString *)email name:(nullable NSString *)name userId:(nullable NSString *)userId error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.identifyUser] phase=enter emailLength=%lu namePresent=%@ userIdPresent=%@", (unsigned long)email.length, (name != nil ? @"true" : @"false"), (userId != nil ? @"true" : @"false")];
    [Luciq identifyUserWithID:userId email:email name:name];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.identifyUser] phase=exit"];
}

- (void)setUserDataData:(NSString *)data error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setUserData] phase=enter length=%lu", (unsigned long)data.length];
    [Luciq setUserData:data];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setUserData] phase=exit"];
}

- (void)logUserEventName:(NSString *)name parameters:(NSDictionary<NSString *, NSString *> *)parameters error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.logUserEvent] phase=enter nameLength=%lu parametersCount=%lu", (unsigned long)name.length, (unsigned long)parameters.count];
    if (parameters.count == 0) {
        [Luciq logUserEventWithName:name];
    } else {
        NSMutableArray<LCQUserEventParam *> *userEventParams = [NSMutableArray arrayWithCapacity:parameters.count];
        [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            [userEventParams addObject:[[LCQUserEventParam alloc] initWithKey:key value:value]];
        }];
        [Luciq logUserEventWithName:name parameters:userEventParams];
    }
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.logUserEvent] phase=exit"];
}

- (void)logOutWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.logOut] phase=enter"];
    [Luciq logOut];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.logOut] phase=exit"];
}

- (void)setLocaleLocale:(NSString *)locale error:(FlutterError *_Nullable *_Nonnull)error {
    LCQLocale resolvedLocale = (ArgsRegistry.locales[locale]).integerValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setLocale] phase=enter locale=%ld", (long)resolvedLocale];
    if (ArgsRegistry.locales[locale] == nil) {
        [LuciqFlutterLogger w:[LuciqFlutterDebugTags core]
                       format:@"[Luciq.setLocale] phase=warn errorType=UnknownEnum locale=%@", locale];
    }
    [Luciq setLocale:resolvedLocale];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setLocale] phase=exit"];
}

- (void)setColorThemeTheme:(NSString *)theme error:(FlutterError *_Nullable *_Nonnull)error {
    LCQColorTheme resolvedTheme = (ArgsRegistry.colorThemes[theme]).integerValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setColorTheme] phase=enter theme=%ld", (long)resolvedTheme];
    if (ArgsRegistry.colorThemes[theme] == nil) {
        [LuciqFlutterLogger w:[LuciqFlutterDebugTags core]
                       format:@"[Luciq.setColorTheme] phase=warn errorType=UnknownEnum theme=%@", theme];
    }
    [Luciq setColorTheme:resolvedTheme];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setColorTheme] phase=exit"];
}

- (void)setWelcomeMessageModeMode:(NSString *)mode error:(FlutterError *_Nullable *_Nonnull)error {
    LCQWelcomeMessageMode resolvedMode = (ArgsRegistry.welcomeMessageStates[mode]).integerValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setWelcomeMessageMode] phase=enter mode=%ld", (long)resolvedMode];
    if (ArgsRegistry.welcomeMessageStates[mode] == nil) {
        [LuciqFlutterLogger w:[LuciqFlutterDebugTags core]
                       format:@"[Luciq.setWelcomeMessageMode] phase=warn errorType=UnknownEnum mode=%@", mode];
    }
    [Luciq setWelcomeMessageMode:resolvedMode];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setWelcomeMessageMode] phase=exit"];
}


- (void)setSessionProfilerEnabledEnabled:(NSNumber *)enabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setSessionProfilerEnabled] phase=enter enabled=%@", ([enabled boolValue] ? @"true" : @"false")];
    [Luciq setSessionProfilerEnabled:[enabled boolValue]];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setSessionProfilerEnabled] phase=exit"];
}

- (void)setValueForStringWithKeyValue:(NSString *)value key:(NSString *)key error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setValueForStringWithKey] phase=enter valueLength=%lu keyLength=%lu", (unsigned long)value.length, (unsigned long)key.length];
    if ([ArgsRegistry.placeholders objectForKey:key]) {
        NSString *resolvedKey = ArgsRegistry.placeholders[key];
        [Luciq setValue:value forStringWithKey:resolvedKey];
    }
    else {
        [LuciqFlutterLogger w:[LuciqFlutterDebugTags core] format:@"[Luciq.setValueForStringWithKey] phase=warn reason=androidOnlyKey key=%@", key];
    }
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setValueForStringWithKey] phase=exit"];
}

- (void)appendTagsTags:(NSArray<NSString *> *)tags error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.appendTags] phase=enter count=%lu", (unsigned long)tags.count];
    [Luciq appendTags:tags];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.appendTags] phase=exit"];
}

- (void)resetTagsWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.resetTags] phase=enter"];
    [Luciq resetTags];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.resetTags] phase=exit"];
}

- (void)getTagsWithCompletion:(nonnull void (^)(NSArray<NSString *> * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.getTags] phase=enter"];
    NSArray<NSString *> *tags = [Luciq getTags];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core]
                   format:@"[Luciq.getTags] phase=exit resultPresent=%@ resultCount=%lu",
        (tags != nil ? @"true" : @"false"),
        (unsigned long)tags.count];
    completion(tags, nil);
}



- (void)setUserAttributeValue:(NSString *)value key:(NSString *)key error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setUserAttribute] phase=enter valueLength=%lu keyLength=%lu", (unsigned long)value.length, (unsigned long)key.length];
    [Luciq setUserAttribute:value withKey:key];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setUserAttribute] phase=exit"];
}

- (void)removeUserAttributeKey:(NSString *)key error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.removeUserAttribute] phase=enter keyLength=%lu", (unsigned long)key.length];
    [Luciq removeUserAttributeForKey:key];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.removeUserAttribute] phase=exit"];
}

- (void)getUserAttributeForKeyKey:(nonnull NSString *)key completion:(nonnull void (^)(NSString * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.getUserAttributeForKey] phase=enter keyLength=%lu", (unsigned long)key.length];
    NSString *result = [Luciq userAttributeForKey:key];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core]
                   format:@"[Luciq.getUserAttributeForKey] phase=exit resultPresent=%@",
        (result != nil ? @"true" : @"false")];
    completion(result, nil);
}

- (void)getUserAttributesWithCompletion:(nonnull void (^)(NSDictionary<NSString *,NSString *> * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.getUserAttributes] phase=enter"];
    NSDictionary<NSString *, NSString *> *result = Luciq.userAttributes;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core]
                   format:@"[Luciq.getUserAttributes] phase=exit resultPresent=%@ resultCount=%lu",
        (result != nil ? @"true" : @"false"),
        (unsigned long)result.count];
    completion(result, nil);
}

- (void)setReproStepsConfigBugMode:(nullable NSString *)bugMode crashMode:(nullable NSString *)crashMode sessionReplayMode:(nullable NSString *)sessionReplayMode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setReproStepsConfig] phase=enter bugModePresent=%@ crashModePresent=%@ sessionReplayModePresent=%@", (bugMode != nil ? @"true" : @"false"), (crashMode != nil ? @"true" : @"false"), (sessionReplayMode != nil ? @"true" : @"false")];
    if (bugMode != nil) {
        LCQUserStepsMode resolvedBugMode = ArgsRegistry.reproModes[bugMode].integerValue;
        if (ArgsRegistry.reproModes[bugMode] == nil) {
            [LuciqFlutterLogger w:[LuciqFlutterDebugTags core]
                           format:@"[Luciq.setReproStepsConfig] phase=warn errorType=UnknownEnum bugMode=%@", bugMode];
        }
        [Luciq setReproStepsFor:LCQIssueTypeBug withMode:resolvedBugMode];
    }

    if (crashMode != nil) {
        LCQUserStepsMode resolvedCrashMode = ArgsRegistry.reproModes[crashMode].integerValue;
        if (ArgsRegistry.reproModes[crashMode] == nil) {
            [LuciqFlutterLogger w:[LuciqFlutterDebugTags core]
                           format:@"[Luciq.setReproStepsConfig] phase=warn errorType=UnknownEnum crashMode=%@", crashMode];
        }
        [Luciq setReproStepsFor:LCQIssueTypeAllCrashes withMode:resolvedCrashMode];
    }

    if (sessionReplayMode != nil) {
        LCQUserStepsMode resolvedSessionReplayMode = ArgsRegistry.reproModes[sessionReplayMode].integerValue;
        if (ArgsRegistry.reproModes[sessionReplayMode] == nil) {
            [LuciqFlutterLogger w:[LuciqFlutterDebugTags core]
                           format:@"[Luciq.setReproStepsConfig] phase=warn errorType=UnknownEnum sessionReplayMode=%@", sessionReplayMode];
        }
        [Luciq setReproStepsFor:LCQIssueTypeSessionReplay withMode:resolvedSessionReplayMode];
    }
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setReproStepsConfig] phase=exit"];
}

- (UIImage *)getImageForAsset:(NSString *)assetName {
    NSString *key = [FlutterDartProject lookupKeyForAsset:assetName];
    NSString *path = [[NSBundle mainBundle] pathForResource:key ofType:nil];

    return [UIImage imageWithContentsOfFile:path];
}

- (void)setCustomBrandingImageLight:(NSString *)light dark:(NSString *)dark error:(FlutterError * _Nullable __autoreleasing *)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setCustomBrandingImage] phase=enter lightPresent=%@ darkPresent=%@", (light.length > 0 ? @"true" : @"false"), (dark.length > 0 ? @"true" : @"false")];
    UIImage *lightImage = [self getImageForAsset:light];
    UIImage *darkImage = [self getImageForAsset:dark];

    if (!lightImage) {
        lightImage = darkImage;
    }
    if (!darkImage) {
        darkImage = lightImage;
    }

    if (@available(iOS 12.0, *)) {
        UIImageAsset *imageAsset = [[UIImageAsset alloc] init];

        [imageAsset registerImage:lightImage withTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        [imageAsset registerImage:darkImage withTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];

        Luciq.customBrandingImage = imageAsset;
    } else {
        UIImage *defaultImage = lightImage;
        if (!lightImage) {
            defaultImage = darkImage;
        }

        Luciq.customBrandingImage = defaultImage.imageAsset;
    }
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setCustomBrandingImage] phase=exit"];
}

- (void)reportScreenChangeScreenName:(NSString *)screenName error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags screenTracking] format:@"[Luciq.reportScreenChange] phase=enter screenNameLength=%lu", (unsigned long)screenName.length];
    SEL setPrivateApiSEL = NSSelectorFromString(@"logViewDidAppearEvent:");
    if ([[Luciq class] respondsToSelector:setPrivateApiSEL]) {
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[Luciq class] methodSignatureForSelector:setPrivateApiSEL]];
        [inv setSelector:setPrivateApiSEL];
        [inv setTarget:[Luciq class]];
        [inv setArgument:&(screenName) atIndex:2];
        [inv invoke];
    }
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags screenTracking] format:@"[Luciq.reportScreenChange] phase=exit"];
}

- (UIFont *)getFontForAsset:(NSString *)assetName  error:(FlutterError *_Nullable *_Nonnull)error {
    NSString *key = [FlutterDartProject lookupKeyForAsset:assetName];
    NSString *path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    CFErrorRef fontError;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef) data);
    CGFontRef cgFont = CGFontCreateWithDataProvider(provider);
    UIFont *font;

    if(!CTFontManagerRegisterGraphicsFont(cgFont, &fontError)){
        CFStringRef errorDescription = CFErrorCopyDescription(fontError);
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags core]
                       format:@"[Luciq.setFont] phase=error errorType=LCQFailedToLoadFont errorMessage=%@",
            (__bridge NSString *)errorDescription];
        *error = [FlutterError errorWithCode:@"LCQFailedToLoadFont" message:(__bridge NSString *)errorDescription details:nil];
        CFRelease(errorDescription);
    } else {
        NSString *fontName = (__bridge NSString *)CGFontCopyFullName(cgFont);
        font = [UIFont fontWithName:fontName size:10.0];
    }

    if (cgFont) CFRelease(cgFont);
    if (provider) CFRelease(provider);

    return font;
}

- (void)setFontFont:(NSString *)fontAsset error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setFont] phase=enter fontAssetPresent=%@", (fontAsset.length > 0 ? @"true" : @"false")];
    UIFont *font = [self getFontForAsset:fontAsset error:error];
    Luciq.font = font;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setFont] phase=exit"];
}

- (void)addFileAttachmentWithURLFilePath:(NSString *)filePath fileName:(NSString *)fileName error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.addFileAttachmentWithURL] phase=enter filePath=%@ fileNameLength=%lu", [LuciqFlutterLogger redactURL:filePath], (unsigned long)fileName.length];
    [Luciq addFileAttachmentWithURL:[NSURL URLWithString:filePath]];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.addFileAttachmentWithURL] phase=exit"];
}

- (void)addFileAttachmentWithDataData:(FlutterStandardTypedData *)data fileName:(NSString *)fileName error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.addFileAttachmentWithData] phase=enter bytes=%lu fileNameLength=%lu", (unsigned long)data.data.length, (unsigned long)fileName.length];
    [Luciq addFileAttachmentWithData:[data data]];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.addFileAttachmentWithData] phase=exit"];
}

- (void)clearFileAttachmentsWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.clearFileAttachments] phase=enter"];
    [Luciq clearFileAttachments];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.clearFileAttachments] phase=exit"];
}

- (void)networkLogData:(NSDictionary<NSString *, id> *)data error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[Luciq.networkLog] phase=enter url=%@ method=%@ responseCode=%d", [LuciqFlutterLogger redactURL:data[@"url"]], data[@"method"], (int32_t)[data[@"responseCode"] integerValue]];
    NSString *url = data[@"url"];
    NSString *method = data[@"method"];
    NSString *requestBody = data[@"requestBody"];
    NSString *responseBody = data[@"responseBody"];
    int32_t responseCode = (int32_t) [data[@"responseCode"] integerValue];
    int64_t requestBodySize = [data[@"requestBodySize"] integerValue];
    int64_t responseBodySize = [data[@"responseBodySize"] integerValue];
    int32_t errorCode = (int32_t) [data[@"errorCode"] integerValue];
    NSString *errorDomain = data[@"errorDomain"];
    NSDictionary *requestHeaders = data[@"requestHeaders"];
    if ([requestHeaders count] == 0) {
        requestHeaders = @{};
    }
    NSDictionary *responseHeaders = data[@"responseHeaders"];
    NSString *contentType = data[@"responseContentType"];
    int64_t duration = [data[@"duration"] integerValue];
    int64_t startTime = [data[@"startTime"] integerValue] * 1000;

    NSString *gqlQueryName = nil;
    NSString *serverErrorMessage = nil;
    NSNumber *isW3cHeaderFound = nil;
    NSNumber *partialId = nil;
    NSNumber *networkStartTimeInSeconds = nil;
    NSString *w3CGeneratedHeader = nil;
    NSString *w3CCaughtHeader = nil;

    if (data[@"gqlQueryName"] != [NSNull null]) {
        gqlQueryName = data[@"gqlQueryName"];
    }
    if (data[@"serverErrorMessage"] != [NSNull null]) {
        serverErrorMessage = data[@"serverErrorMessage"];
    }
    if (data[@"partialId"] != [NSNull null]) {
        partialId = data[@"partialId"];
    }

    if (data[@"isW3cHeaderFound"] != [NSNull null]) {
        isW3cHeaderFound = data[@"isW3cHeaderFound"];
    }

    if (data[@"networkStartTimeInSeconds"] != [NSNull null]) {
        networkStartTimeInSeconds = data[@"networkStartTimeInSeconds"];
    }

    if (data[@"w3CGeneratedHeader"] != [NSNull null]) {
        w3CGeneratedHeader = data[@"w3CGeneratedHeader"];
    }

    if (data[@"w3CCaughtHeader"] != [NSNull null]) {
        w3CCaughtHeader = data[@"w3CCaughtHeader"];
    }



    [LCQNetworkLogger addNetworkLogWithUrl:url
                                    method:method
                               requestBody:requestBody
                           requestBodySize:requestBodySize
                              responseBody:responseBody
                          responseBodySize:responseBodySize
                              responseCode:responseCode
                            requestHeaders:requestHeaders
                           responseHeaders:responseHeaders
                               contentType:contentType
                               errorDomain:errorDomain
                                 errorCode:errorCode
                                 startTime:startTime
                                  duration:duration
                              gqlQueryName:gqlQueryName
                        serverErrorMessage:serverErrorMessage
                             isW3cCaughted:isW3cHeaderFound
                                 partialID:partialId
                                 timestamp:networkStartTimeInSeconds
                   generatedW3CTraceparent:w3CGeneratedHeader
                    caughtedW3CTraceparent:w3CCaughtHeader];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[Luciq.networkLog] phase=exit"];
}

- (void)willRedirectToStoreWithError:(FlutterError * _Nullable __autoreleasing *)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.willRedirectToStore] phase=enter"];
    [Luciq willRedirectToAppStore];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.willRedirectToStore] phase=exit"];
}

- (void)addFeatureFlagsFeatureFlagsMap:(nonnull NSDictionary<NSString *,NSString *> *)featureFlagsMap error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[Luciq.addFeatureFlags] phase=enter count=%lu", (unsigned long)featureFlagsMap.count];
    NSMutableArray<LCQFeatureFlag *> *featureFlags = [NSMutableArray array];
    for(id key in featureFlagsMap){
        NSString* variant =((NSString * )[featureFlagsMap objectForKey:key]);
        if ([variant length]==0) {
            [featureFlags addObject:[[LCQFeatureFlag alloc] initWithName:key]];
        }
        else{
            [featureFlags addObject:[[LCQFeatureFlag alloc] initWithName:key variant:variant]];

        }
    }
    [Luciq addFeatureFlags:featureFlags];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[Luciq.addFeatureFlags] phase=exit"];
}


- (void)removeAllFeatureFlagsWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[Luciq.removeAllFeatureFlags] phase=enter"];
    [Luciq removeAllFeatureFlags];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[Luciq.removeAllFeatureFlags] phase=exit"];
}


- (void)removeFeatureFlagsFeatureFlags:(nonnull NSArray<NSString *> *)featureFlags error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[Luciq.removeFeatureFlags] phase=enter count=%lu", (unsigned long)featureFlags.count];

    NSMutableArray<LCQFeatureFlag *> *features = [NSMutableArray array];
       for(id item in featureFlags){
               [features addObject:[[LCQFeatureFlag alloc] initWithName:item]];
           }
    @try {
        [Luciq removeFeatureFlags:features];
        [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[Luciq.removeFeatureFlags] phase=exit"];
    } @catch (NSException *exception) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags featureFlags]
                       format:@"[Luciq.removeFeatureFlags] phase=error errorType=%@ errorMessage=%@",
            NSStringFromClass([exception class]),
            (exception.reason ?: @"")];

    }
}
- (void)registerFeatureFlagChangeListenerWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[Luciq.registerFeatureFlagChangeListener] phase=enter platform=iOS noop=true"];
    // Android only. We still need this method to exist to match the Pigeon-generated protocol.
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[Luciq.registerFeatureFlagChangeListener] phase=exit"];
}


- (nullable NSDictionary<NSString *,NSNumber *> *)isW3CFeatureFlagsEnabledWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[Luciq.isW3CFeatureFlagsEnabled] phase=enter"];
    NSDictionary<NSString * , NSNumber *> *result= @{
        @"isW3cExternalTraceIDEnabled":[NSNumber numberWithBool:LCQNetworkLogger.w3ExternalTraceIDEnabled] ,
        @"isW3cExternalGeneratedHeaderEnabled":[NSNumber numberWithBool:LCQNetworkLogger.w3ExternalGeneratedHeaderEnabled] ,
        @"isW3cCaughtHeaderEnabled":[NSNumber numberWithBool:LCQNetworkLogger.w3CaughtHeaderEnabled] ,

    };
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network]
                   format:@"[Luciq.isW3CFeatureFlagsEnabled] phase=exit resultPresent=%@ resultCount=%lu",
        (result != nil ? @"true" : @"false"),
        (unsigned long)result.count];
    return  result;
}

- (void)logUserStepsGestureType:(NSString *)gestureType message:(NSString *)message viewName:(NSString *)viewName error:(FlutterError * _Nullable __autoreleasing *)error
{
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.logUserSteps] phase=enter gestureType=%@ messageLength=%lu viewNameLength=%lu", gestureType, (unsigned long)message.length, (unsigned long)viewName.length];
    @try {

        if (ArgsRegistry.userStepsGesture[gestureType] == nil) {
            [LuciqFlutterLogger w:[LuciqFlutterDebugTags core]
                           format:@"[Luciq.logUserSteps] phase=warn errorType=UnknownEnum gestureType=%@", gestureType];
        }
        LCQUIEventType event = ArgsRegistry.userStepsGesture[gestureType].integerValue;
        LCQUserStep *userStep = [[LCQUserStep alloc] initWithEvent:event automatic: YES];

        userStep = [userStep setMessage: message];
        userStep =  [userStep setViewTypeName:viewName];
        [userStep logUserStep];
        [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.logUserSteps] phase=exit"];
    }
    @catch (NSException *exception) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags core]
                       format:@"[Luciq.logUserSteps] phase=error errorType=%@ errorMessage=%@",
            NSStringFromClass([exception class]),
            (exception.reason ?: @"")];

    }
}


- (void)setEnableUserStepsIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setEnableUserSteps] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    Luciq.trackUserSteps = isEnabled.boolValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setEnableUserSteps] phase=exit"];
}

- (void)enableAutoMaskingAutoMasking:(nonnull NSArray<NSString *> *)autoMasking error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags privateView] format:@"[Luciq.enableAutoMasking] phase=enter count=%lu", (unsigned long)autoMasking.count];
    LCQAutoMaskScreenshotOption resolvedEvents = 0;

    for (NSString *event in autoMasking) {
        if (ArgsRegistry.autoMasking[event] == nil) {
            [LuciqFlutterLogger w:[LuciqFlutterDebugTags privateView]
                           format:@"[Luciq.enableAutoMasking] phase=warn errorType=UnknownEnum event=%@", event];
        }
        resolvedEvents |= (ArgsRegistry.autoMasking[event]).integerValue;
    }

    [Luciq setAutoMaskScreenshots: resolvedEvents];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags privateView] format:@"[Luciq.enableAutoMasking] phase=exit"];
}
+ (void)setScreenshotMaskingHandler:(nullable void (^)(UIImage * _Nonnull __strong, void (^ _Nonnull __strong)(UIImage * _Nonnull __strong)))maskingHandler {
    [Luciq setScreenshotMaskingHandler:maskingHandler];
}

- (void)setNetworkLogBodyEnabledIsEnabled:(NSNumber *)isEnabled
                          error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[Luciq.setNetworkLogBodyEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    LCQNetworkLogger.logBodyEnabled = [isEnabled boolValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[Luciq.setNetworkLogBodyEnabled] phase=exit"];
}


- (void)setAppVariantAppVariant:(nonnull NSString *)appVariant error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setAppVariant] phase=enter appVariantLength=%lu", (unsigned long)appVariant.length];
    Luciq.appVariant = appVariant;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setAppVariant] phase=exit"];
}


- (void)setThemeThemeConfig:(NSDictionary<NSString *, id> *)themeConfig error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setTheme] phase=enter keysCount=%lu", (unsigned long)themeConfig.count];
    LCQTheme *theme = [[LCQTheme alloc] init];

    NSDictionary *colorMapping = @{
        @"primaryColor": ^(UIColor *color) { theme.primaryColor = color; },
        @"backgroundColor": ^(UIColor *color) { theme.backgroundColor = color; },
        @"titleTextColor": ^(UIColor *color) { theme.titleTextColor = color; },
        @"subtitleTextColor": ^(UIColor *color) { theme.subtitleTextColor = color; },
        @"primaryTextColor": ^(UIColor *color) { theme.primaryTextColor = color; },
        @"secondaryTextColor": ^(UIColor *color) { theme.secondaryTextColor = color; },
        @"callToActionTextColor": ^(UIColor *color) { theme.callToActionTextColor = color; },
        @"headerBackgroundColor": ^(UIColor *color) { theme.headerBackgroundColor = color; },
        @"footerBackgroundColor": ^(UIColor *color) { theme.footerBackgroundColor = color; },
        @"rowBackgroundColor": ^(UIColor *color) { theme.rowBackgroundColor = color; },
        @"selectedRowBackgroundColor": ^(UIColor *color) { theme.selectedRowBackgroundColor = color; },
        @"rowSeparatorColor": ^(UIColor *color) { theme.rowSeparatorColor = color; }
    };

    for (NSString *key in colorMapping) {
        if (themeConfig[key]) {
            NSString *colorString = themeConfig[key];
            UIColor *color = [self colorFromHexString:colorString];
            if (color) {
                void (^setter)(UIColor *) = colorMapping[key];
                setter(color);
            }
        }
    }

    [self setFontIfPresent:themeConfig[@"primaryFontPath"] ?: themeConfig[@"primaryFontAsset"] forTheme:theme type:@"primary"];
    [self setFontIfPresent:themeConfig[@"secondaryFontPath"] ?: themeConfig[@"secondaryFontAsset"] forTheme:theme type:@"secondary"];
    [self setFontIfPresent:themeConfig[@"ctaFontPath"] ?: themeConfig[@"ctaFontAsset"] forTheme:theme type:@"cta"];

    Luciq.theme = theme;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setTheme] phase=exit"];
}

- (void)setFontIfPresent:(NSString *)fontPath forTheme:(LCQTheme *)theme type:(NSString *)type {
    if (!fontPath || fontPath.length == 0 || !theme || !type) return;

    if (!_registeredFonts) {
        _registeredFonts = [NSMutableSet set];
    }

    // Check if font is already registered
    if ([_registeredFonts containsObject:fontPath]) {
        UIFont *font = [UIFont fontWithName:fontPath size:UIFont.systemFontSize];
        if (font) {
            [self setFont:font forTheme:theme type:type];
        }
        return;
    }

    // Try to load font from system fonts first
    UIFont *font = [UIFont fontWithName:fontPath size:UIFont.systemFontSize];
    if (font) {
        [_registeredFonts addObject:fontPath];
        [self setFont:font forTheme:theme type:type];
        return;
    }

    // Try to load font from bundle
    font = [self loadFontFromPath:fontPath];
    if (font) {
        [_registeredFonts addObject:fontPath];
        [self setFont:font forTheme:theme type:type];
    }
}

- (UIFont *)loadFontFromPath:(NSString *)fontPath {
    NSString *fontFileName = [fontPath stringByDeletingPathExtension];
    NSArray *fontExtensions = @[@"ttf", @"otf", @"woff", @"woff2"];

    // Find font file in bundle
    NSString *fontFilePath = nil;
    for (NSString *extension in fontExtensions) {
        fontFilePath = [[NSBundle mainBundle] pathForResource:fontFileName ofType:extension];
        if (fontFilePath) break;
    }

    if (!fontFilePath) {
        return nil;
    }

    // Load font data
    NSData *fontData = [NSData dataWithContentsOfFile:fontFilePath];
    if (!fontData) {
        return nil;
    }

    // Create data provider
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)fontData);
    if (!provider) {
        return nil;
    }

    // Create CG font
    CGFontRef cgFont = CGFontCreateWithDataProvider(provider);
    CGDataProviderRelease(provider);

    if (!cgFont) {
        return nil;
    }

    // Register font
    CFErrorRef error = NULL;
    BOOL registered = CTFontManagerRegisterGraphicsFont(cgFont, &error);

    if (!registered) {
        if (error) {
            CFStringRef description = CFErrorCopyDescription(error);
            CFRelease(description);
            CFRelease(error);
        }
        CGFontRelease(cgFont);
        return nil;
    }

    // Get PostScript name and create UIFont
    NSString *postScriptName = (__bridge_transfer NSString *)CGFontCopyPostScriptName(cgFont);
    CGFontRelease(cgFont);

    if (!postScriptName) {
        return nil;
    }

    return [UIFont fontWithName:postScriptName size:UIFont.systemFontSize];
}

- (void)setFont:(UIFont *)font forTheme:(LCQTheme *)theme type:(NSString *)type {
    if (!font || !theme || !type) return;

    if ([type isEqualToString:@"primary"]) {
        theme.primaryTextFont = font;
    } else if ([type isEqualToString:@"secondary"]) {
        theme.secondaryTextFont = font;
    } else if ([type isEqualToString:@"cta"]) {
        theme.callToActionTextFont = font;
    }
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];

    if (cleanString.length == 6) {
        unsigned int rgbValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:cleanString];
        [scanner scanHexInt:&rgbValue];

        return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                               green:((rgbValue & 0xFF00) >> 8) / 255.0
                                blue:(rgbValue & 0xFF) / 255.0
                               alpha:1.0];
    } else if (cleanString.length == 8) {
        unsigned int rgbaValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:cleanString];
        [scanner scanHexInt:&rgbaValue];

        return [UIColor colorWithRed:((rgbaValue & 0xFF000000) >> 24) / 255.0
                               green:((rgbaValue & 0xFF0000) >> 16) / 255.0
                                blue:((rgbaValue & 0xFF00) >> 8) / 255.0
                               alpha:(rgbaValue & 0xFF) / 255.0];
    }

    return [UIColor blackColor];
}

- (void)setFullscreenIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setFullscreen] phase=enter isEnabled=%@ platform=iOS noop=true", ([isEnabled boolValue] ? @"true" : @"false")];
    // Empty implementation as requested
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setFullscreen] phase=exit"];
}

- (void)getNetworkBodyMaxSizeWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[Luciq.getNetworkBodyMaxSize] phase=enter"];
    NSNumber *result = @(LCQNetworkLogger.getNetworkBodyMaxSize);
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network]
                   format:@"[Luciq.getNetworkBodyMaxSize] phase=exit resultPresent=%@",
        (result != nil ? @"true" : @"false")];
    completion(result, nil);
}

- (void)setNetworkAutoMaskingEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[Luciq.setNetworkAutoMaskingEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    LCQNetworkLogger.autoMaskingEnabled = [isEnabled boolValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[Luciq.setNetworkAutoMaskingEnabled] phase=exit"];
}

- (void)setWebViewMonitoringEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setWebViewMonitoringEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    Luciq.webViewMonitoringEnabled = [isEnabled boolValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setWebViewMonitoringEnabled] phase=exit"];
}

- (void)setWebViewUserInteractionsTrackingEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setWebViewUserInteractionsTrackingEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    Luciq.webViewUserInteractionsTrackingEnabled = [isEnabled boolValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[Luciq.setWebViewUserInteractionsTrackingEnabled] phase=exit"];
}

- (void)setWebViewNetworkTrackingEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[Luciq.setWebViewNetworkTrackingEnabled] phase=enter isEnabled=%@", ([isEnabled boolValue] ? @"true" : @"false")];
    Luciq.webViewNetworkTrackingEnabled = [isEnabled boolValue];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[Luciq.setWebViewNetworkTrackingEnabled] phase=exit"];
}


@end
