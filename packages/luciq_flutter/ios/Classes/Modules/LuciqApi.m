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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    Luciq.enabled = [isEnabled boolValue];
}

- (nullable NSNumber *)isBuiltWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[isBuilt]"];
    return @(YES);
}


- (nullable NSNumber *)isEnabledWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[isEnabled]"];
    return @(Luciq.enabled);
}

- (void)initToken:(nonnull NSString *)token invocationEvents:(nonnull NSArray<NSString *> *)invocationEvents debugLogsLevel:(nonnull NSString *)debugLogsLevel appVariant:(nullable NSString *)appVariant error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {

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
        resolvedEvents |= (ArgsRegistry.invocationEvents[event]).integerValue;
    }

    LCQSDKDebugLogsLevel resolvedLogLevel = (ArgsRegistry.sdkLogLevels[debugLogsLevel]).integerValue;

    [LuciqFlutterLogger setLevel:resolvedLogLevel];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core]
                   format:@"[init] tokenPresent=%@ invocationEventsCount=%lu debugLogsLevel=%ld appVariantPresent=%@",
        (token.length > 0 ? @"YES" : @"NO"),
        (unsigned long)invocationEvents.count,
        (long)resolvedLogLevel,
        (appVariant != nil ? @"YES" : @"NO")];

    [Luciq setSdkDebugLogsLevel:resolvedLogLevel];
    [Luciq startWithToken:token invocationEvents:resolvedEvents];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[init] native init dispatched"];
    Luciq.sendEventsSwizzling = false;
}

- (void)showWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[show]"];
    [Luciq show];
}

- (void)showWelcomeMessageWithModeMode:(NSString *)mode error:(FlutterError *_Nullable *_Nonnull)error {
    LCQWelcomeMessageMode resolvedMode = (ArgsRegistry.welcomeMessageStates[mode]).integerValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[showWelcomeMessageWithMode] mode=%ld", (long)resolvedMode];
    [Luciq showWelcomeMessageWithMode:resolvedMode];
}

- (void)identifyUserEmail:(NSString *)email name:(nullable NSString *)name userId:(nullable NSString *)userId error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[identifyUser] emailLength=%lu namePresent=%@ userIdPresent=%@", (unsigned long)email.length, (name != nil ? @"YES" : @"NO"), (userId != nil ? @"YES" : @"NO")];
    [Luciq identifyUserWithID:userId email:email name:name];
}

- (void)setUserDataData:(NSString *)data error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setUserData] length=%lu", (unsigned long)data.length];
    [Luciq setUserData:data];
}

- (void)logUserEventName:(NSString *)name error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[logUserEvent] nameLength=%lu", (unsigned long)name.length];
    [Luciq logUserEventWithName:name];
}

- (void)logOutWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[logOut]"];
    [Luciq logOut];
}

- (void)setLocaleLocale:(NSString *)locale error:(FlutterError *_Nullable *_Nonnull)error {
    LCQLocale resolvedLocale = (ArgsRegistry.locales[locale]).integerValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setLocale] locale=%ld", (long)resolvedLocale];
    [Luciq setLocale:resolvedLocale];
}

- (void)setColorThemeTheme:(NSString *)theme error:(FlutterError *_Nullable *_Nonnull)error {
    LCQColorTheme resolvedTheme = (ArgsRegistry.colorThemes[theme]).integerValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setColorTheme] theme=%ld", (long)resolvedTheme];
    [Luciq setColorTheme:resolvedTheme];
}

- (void)setWelcomeMessageModeMode:(NSString *)mode error:(FlutterError *_Nullable *_Nonnull)error {
    LCQWelcomeMessageMode resolvedMode = (ArgsRegistry.welcomeMessageStates[mode]).integerValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setWelcomeMessageMode] mode=%ld", (long)resolvedMode];
    [Luciq setWelcomeMessageMode:resolvedMode];
}


- (void)setSessionProfilerEnabledEnabled:(NSNumber *)enabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setSessionProfilerEnabled] enabled=%@", ([enabled boolValue] ? @"YES" : @"NO")];
    [Luciq setSessionProfilerEnabled:[enabled boolValue]];
}

- (void)setValueForStringWithKeyValue:(NSString *)value key:(NSString *)key error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setValueForStringWithKey] valueLength=%lu keyLength=%lu", (unsigned long)value.length, (unsigned long)key.length];
    if ([ArgsRegistry.placeholders objectForKey:key]) {
        NSString *resolvedKey = ArgsRegistry.placeholders[key];
        [Luciq setValue:value forStringWithKey:resolvedKey];
    }
    else {
        [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setValueForStringWithKey] key is Android-only, ignored"];
    }
}

- (void)appendTagsTags:(NSArray<NSString *> *)tags error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[appendTags] count=%lu", (unsigned long)tags.count];
    [Luciq appendTags:tags];
}

- (void)resetTagsWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[resetTags]"];
    [Luciq resetTags];
}

- (void)getTagsWithCompletion:(nonnull void (^)(NSArray<NSString *> * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[getTags]"];
    completion([Luciq getTags], nil);
}



- (void)setUserAttributeValue:(NSString *)value key:(NSString *)key error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setUserAttribute] valueLength=%lu keyLength=%lu", (unsigned long)value.length, (unsigned long)key.length];
    [Luciq setUserAttribute:value withKey:key];
}

- (void)removeUserAttributeKey:(NSString *)key error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[removeUserAttribute] keyLength=%lu", (unsigned long)key.length];
    [Luciq removeUserAttributeForKey:key];
}

- (void)getUserAttributeForKeyKey:(nonnull NSString *)key completion:(nonnull void (^)(NSString * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[getUserAttributeForKey] keyLength=%lu", (unsigned long)key.length];
    completion([Luciq userAttributeForKey:key], nil);
}

- (void)getUserAttributesWithCompletion:(nonnull void (^)(NSDictionary<NSString *,NSString *> * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[getUserAttributes]"];
    completion(Luciq.userAttributes, nil);
}

- (void)setReproStepsConfigBugMode:(nullable NSString *)bugMode crashMode:(nullable NSString *)crashMode sessionReplayMode:(nullable NSString *)sessionReplayMode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setReproStepsConfig] bugModePresent=%@ crashModePresent=%@ sessionReplayModePresent=%@", (bugMode != nil ? @"YES" : @"NO"), (crashMode != nil ? @"YES" : @"NO"), (sessionReplayMode != nil ? @"YES" : @"NO")];
    if (bugMode != nil) {
        LCQUserStepsMode resolvedBugMode = ArgsRegistry.reproModes[bugMode].integerValue;
        [Luciq setReproStepsFor:LCQIssueTypeBug withMode:resolvedBugMode];
    }
    
    if (crashMode != nil) {
        LCQUserStepsMode resolvedCrashMode = ArgsRegistry.reproModes[crashMode].integerValue;
        [Luciq setReproStepsFor:LCQIssueTypeAllCrashes withMode:resolvedCrashMode];
    }
    
    if (sessionReplayMode != nil) {
        LCQUserStepsMode resolvedSessionReplayMode = ArgsRegistry.reproModes[sessionReplayMode].integerValue;
        [Luciq setReproStepsFor:LCQIssueTypeSessionReplay withMode:resolvedSessionReplayMode];
    }
}

- (UIImage *)getImageForAsset:(NSString *)assetName {
    NSString *key = [FlutterDartProject lookupKeyForAsset:assetName];
    NSString *path = [[NSBundle mainBundle] pathForResource:key ofType:nil];

    return [UIImage imageWithContentsOfFile:path];
}

- (void)setCustomBrandingImageLight:(NSString *)light dark:(NSString *)dark error:(FlutterError * _Nullable __autoreleasing *)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setCustomBrandingImage] lightPresent=%@ darkPresent=%@", (light.length > 0 ? @"YES" : @"NO"), (dark.length > 0 ? @"YES" : @"NO")];
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
}

- (void)reportScreenChangeScreenName:(NSString *)screenName error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags screenTracking] format:@"[reportScreenChange] screenNameLength=%lu", (unsigned long)screenName.length];
    SEL setPrivateApiSEL = NSSelectorFromString(@"logViewDidAppearEvent:");
    if ([[Luciq class] respondsToSelector:setPrivateApiSEL]) {
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[Luciq class] methodSignatureForSelector:setPrivateApiSEL]];
        [inv setSelector:setPrivateApiSEL];
        [inv setTarget:[Luciq class]];
        [inv setArgument:&(screenName) atIndex:2];
        [inv invoke];
    }
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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setFont] fontAssetPresent=%@", (fontAsset.length > 0 ? @"YES" : @"NO")];
    UIFont *font = [self getFontForAsset:fontAsset error:error];
    Luciq.font = font;
}

- (void)addFileAttachmentWithURLFilePath:(NSString *)filePath fileName:(NSString *)fileName error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[addFileAttachmentWithURL] filePath=%@ fileNameLength=%lu", [LuciqFlutterLogger redactURL:filePath], (unsigned long)fileName.length];
    [Luciq addFileAttachmentWithURL:[NSURL URLWithString:filePath]];
}

- (void)addFileAttachmentWithDataData:(FlutterStandardTypedData *)data fileName:(NSString *)fileName error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[addFileAttachmentWithData] bytes=%lu fileNameLength=%lu", (unsigned long)data.data.length, (unsigned long)fileName.length];
    [Luciq addFileAttachmentWithData:[data data]];
}

- (void)clearFileAttachmentsWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[clearFileAttachments]"];
    [Luciq clearFileAttachments];
}

- (void)networkLogData:(NSDictionary<NSString *, id> *)data error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[networkLog] url=%@ method=%@ responseCode=%d", [LuciqFlutterLogger redactURL:data[@"url"]], data[@"method"], (int32_t)[data[@"responseCode"] integerValue]];
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
}

- (void)willRedirectToStoreWithError:(FlutterError * _Nullable __autoreleasing *)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[willRedirectToStore]"];
    [Luciq willRedirectToAppStore];
}

- (void)addFeatureFlagsFeatureFlagsMap:(nonnull NSDictionary<NSString *,NSString *> *)featureFlagsMap error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[addFeatureFlags] count=%lu", (unsigned long)featureFlagsMap.count];
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
}


- (void)removeAllFeatureFlagsWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[removeAllFeatureFlags]"];
    [Luciq removeAllFeatureFlags];

}


- (void)removeFeatureFlagsFeatureFlags:(nonnull NSArray<NSString *> *)featureFlags error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[removeFeatureFlags] count=%lu", (unsigned long)featureFlags.count];

    NSMutableArray<LCQFeatureFlag *> *features = [NSMutableArray array];
       for(id item in featureFlags){
               [features addObject:[[LCQFeatureFlag alloc] initWithName:item]];
           }
    @try {
        [Luciq removeFeatureFlags:features];
    } @catch (NSException *exception) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags featureFlags] format:@"[removeFeatureFlags] exception=%@", NSStringFromClass([exception class])];

    }
}
- (void)registerFeatureFlagChangeListenerWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags featureFlags] format:@"[registerFeatureFlagChangeListener] iOS noop"];
    // Android only. We still need this method to exist to match the Pigeon-generated protocol.

}


- (nullable NSDictionary<NSString *,NSNumber *> *)isW3CFeatureFlagsEnabledWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[isW3CFeatureFlagsEnabled]"];
    NSDictionary<NSString * , NSNumber *> *result= @{
        @"isW3cExternalTraceIDEnabled":[NSNumber numberWithBool:LCQNetworkLogger.w3ExternalTraceIDEnabled] ,
        @"isW3cExternalGeneratedHeaderEnabled":[NSNumber numberWithBool:LCQNetworkLogger.w3ExternalGeneratedHeaderEnabled] ,
        @"isW3cCaughtHeaderEnabled":[NSNumber numberWithBool:LCQNetworkLogger.w3CaughtHeaderEnabled] ,

    };
    return  result;
}

- (void)logUserStepsGestureType:(NSString *)gestureType message:(NSString *)message viewName:(NSString *)viewName error:(FlutterError * _Nullable __autoreleasing *)error
{
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[logUserSteps] gestureType=%@ messageLength=%lu viewNameLength=%lu", gestureType, (unsigned long)message.length, (unsigned long)viewName.length];
    @try {

        LCQUIEventType event = ArgsRegistry.userStepsGesture[gestureType].integerValue;
        LCQUserStep *userStep = [[LCQUserStep alloc] initWithEvent:event automatic: YES];

        userStep = [userStep setMessage: message];
        userStep =  [userStep setViewTypeName:viewName];
        [userStep logUserStep];
    }
    @catch (NSException *exception) {
        [LuciqFlutterLogger e:[LuciqFlutterDebugTags core] format:@"[logUserSteps] exception=%@", NSStringFromClass([exception class])];

    }
}


- (void)setEnableUserStepsIsEnabled:(nonnull NSNumber *)isEnabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setEnableUserSteps] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    Luciq.trackUserSteps = isEnabled.boolValue;
}

- (void)enableAutoMaskingAutoMasking:(nonnull NSArray<NSString *> *)autoMasking error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags privateView] format:@"[enableAutoMasking] count=%lu", (unsigned long)autoMasking.count];
    LCQAutoMaskScreenshotOption resolvedEvents = 0;

    for (NSString *event in autoMasking) {
        resolvedEvents |= (ArgsRegistry.autoMasking[event]).integerValue;
    }

    [Luciq setAutoMaskScreenshots: resolvedEvents];

}
+ (void)setScreenshotMaskingHandler:(nullable void (^)(UIImage * _Nonnull __strong, void (^ _Nonnull __strong)(UIImage * _Nonnull __strong)))maskingHandler {
    [Luciq setScreenshotMaskingHandler:maskingHandler];
}

- (void)setNetworkLogBodyEnabledIsEnabled:(NSNumber *)isEnabled
                          error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[setNetworkLogBodyEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    LCQNetworkLogger.logBodyEnabled = [isEnabled boolValue];
}


- (void)setAppVariantAppVariant:(nonnull NSString *)appVariant error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setAppVariant] appVariantLength=%lu", (unsigned long)appVariant.length];

    Luciq.appVariant = appVariant;

}


- (void)setThemeThemeConfig:(NSDictionary<NSString *, id> *)themeConfig error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setTheme] keysCount=%lu", (unsigned long)themeConfig.count];
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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setFullscreen] isEnabled=%@ iOS noop", ([isEnabled boolValue] ? @"YES" : @"NO")];
    // Empty implementation as requested
}

- (void)getNetworkBodyMaxSizeWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[getNetworkBodyMaxSize]"];
    completion(@(LCQNetworkLogger.getNetworkBodyMaxSize), nil);
}

- (void)setNetworkAutoMaskingEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[setNetworkAutoMaskingEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    LCQNetworkLogger.autoMaskingEnabled = [isEnabled boolValue];
}

- (void)setWebViewMonitoringEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setWebViewMonitoringEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    Luciq.webViewMonitoringEnabled = [isEnabled boolValue];
}

- (void)setWebViewUserInteractionsTrackingEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags core] format:@"[setWebViewUserInteractionsTrackingEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    Luciq.webViewUserInteractionsTrackingEnabled = [isEnabled boolValue];
}

- (void)setWebViewNetworkTrackingEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags network] format:@"[setWebViewNetworkTrackingEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    Luciq.webViewNetworkTrackingEnabled = [isEnabled boolValue];
}

@end
