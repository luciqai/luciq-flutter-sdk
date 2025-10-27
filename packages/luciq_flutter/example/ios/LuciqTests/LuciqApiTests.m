#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "OCMock/OCMock.h"
#import "LuciqApi.h"
#import "LuciqSDK/LuciqSDK.h"
#import "Util/Luciq+Test.h"
#import "LCQNetworkLogger+CP.h"
#import "Flutter/Flutter.h"
#import "luciq_flutter/LCQAPM+PrivateAPIs.h"
#import "luciq_flutter/LCQNetworkLogger+CP.h"

@interface LuciqTests : XCTestCase

@property (nonatomic, strong) id mLuciq;
@property (nonatomic, strong) LuciqApi *api;
@property (nonatomic, strong) id mApi;
@property (nonatomic, strong) id mNetworkLogger;

@end

@implementation LuciqTests

- (void)setUp {
    self.mLuciq = OCMClassMock([Luciq class]);
    self.mNetworkLogger = OCMClassMock([LCQNetworkLogger class]);
    self.api = [[LuciqApi alloc] init];
    self.mApi = OCMPartialMock(self.api);
}

- (void)testSetEnabled {
    NSNumber *isEnabled = @1;
    FlutterError *error;

    [self.api setEnabledIsEnabled:isEnabled error:&error];

    OCMVerify([self.mLuciq setEnabled:YES]);
}

- (void)testInit {
    NSString *token = @"app-token";
    NSString *appVariant = @"app-variant";

    NSArray<NSString *> *invocationEvents = @[@"InvocationEvent.floatingButton", @"InvocationEvent.screenshot"];
    NSString *logLevel = @"LogLevel.error";
    FlutterError *error;
    
    [self.api initToken:token invocationEvents:invocationEvents debugLogsLevel:logLevel appVariant:appVariant error:&error];

    OCMVerify([self.mLuciq setCurrentPlatform:LCQPlatformFlutter]);

    OCMVerify([self.mLuciq setSdkDebugLogsLevel:LCQSDKDebugLogsLevelError]);

    OCMVerify([self.mLuciq startWithToken:token invocationEvents:(LCQInvocationEventFloatingButton | LCQInvocationEventScreenshot)]);

    XCTAssertEqual(Luciq.appVariant, appVariant);

}

- (void)testShow {
    FlutterError *error;
    
    [self.api showWithError:&error];
    
    OCMVerify([self.mLuciq show]);
}

- (void)testShowWelcomeMessageWithMode {
    NSString *mode = @"WelcomeMessageMode.live";
    FlutterError *error;

    [self.api showWelcomeMessageWithModeMode:mode error:&error];

    OCMVerify([self.mLuciq showWelcomeMessageWithMode:LCQWelcomeMessageModeLive]);
}

- (void)testIdentifyUser {
    NSString *email = @"inst@bug.com";
    NSString *name = @"John Doe";
    NSString *userId = @"123";
    FlutterError *error;

    [self.api identifyUserEmail:email name:name userId:userId error:&error];

    OCMVerify([self.mLuciq identifyUserWithID:userId email:email name:name]);
}

- (void)testSetUserData {
    NSString *data = @"premium";
    FlutterError *error;

    [self.api setUserDataData:data error:&error];

    OCMVerify([self.mLuciq setUserData:data]);
}

- (void)testLogUserEvent {
    NSString *name = @"sign_up";
    FlutterError *error;

    [self.api logUserEventName:name error:&error];

    OCMVerify([self.mLuciq logUserEventWithName:name]);
}

- (void)testLogOut {
    FlutterError *error;

    [self.api logOutWithError:&error];

    OCMVerify([self.mLuciq logOut]);
}

- (void)testSetLocale {
    NSString *locale = @"LCQLocale.japanese";
    FlutterError *error;

    [self.api setLocaleLocale:locale error:&error];

    OCMVerify([(Class) self.mLuciq setLocale:LCQLocaleJapanese]);
}

- (void)testSetColorTheme {
    NSString *theme = @"ColorTheme.dark";
    FlutterError *error;

    [self.api setColorThemeTheme:theme error:&error];

    OCMVerify([self.mLuciq setColorTheme:LCQColorThemeDark]);
}

- (void)testSetWelcomeMessageMode {
    NSString *mode = @"WelcomeMessageMode.beta";
    FlutterError *error;

    [self.api setWelcomeMessageModeMode:mode error:&error];

    OCMVerify([self.mLuciq setWelcomeMessageMode:LCQWelcomeMessageModeBeta]);
}


- (void)testSetSessionProfilerEnabled {
    NSNumber *isEnabled = @1;
    FlutterError *error;

    [self.api setSessionProfilerEnabledEnabled:isEnabled error:&error];

    OCMVerify([self.mLuciq setSessionProfilerEnabled:YES]);
}

- (void)testSetValueForStringWithKeyWhenKeyExists {
    NSString *value = @"Send a bug report";
    NSString *key = @"CustomTextPlaceHolderKey.reportBug";
    FlutterError *error;

    [self.api setValueForStringWithKeyValue:value key:key error:&error];

    OCMVerify([self.mLuciq setValue:value forStringWithKey:kLCQReportBugStringName]);
}

- (void)testSetValueForStringWithKeyWhenKeyDoesNotExist {
    NSString *value = @"Wingardium Leviosa";
    NSString *key = @"CustomTextPlaceHolderKey.wingardiumLeviosa";
    FlutterError *error;

    [self.api setValueForStringWithKeyValue:value key:key error:&error];

    OCMVerify(never(), [self.mLuciq setValue:value forStringWithKey:kLCQReportBugStringName]);
}

- (void)testAppendTags {
    NSArray<NSString *> *tags = @[@"premium", @"star"];
    FlutterError *error;

    [self.api appendTagsTags:tags error:&error];

    OCMVerify([self.mLuciq appendTags:tags]);
}

- (void)testResetTags {
    FlutterError *error;

    [self.api resetTagsWithError:&error];

    OCMVerify([self.mLuciq resetTags]);
}

- (void)testGetTags {
    NSArray<NSString *> *expected = @[@"active"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Call completion handler"];
    
    OCMStub([self.mLuciq getTags]).andReturn(expected);

    [self.api getTagsWithCompletion:^(NSArray<NSString *> *actual, FlutterError *error) {
        [expectation fulfill];
        XCTAssertEqual(expected, actual);
    }];

    OCMVerify([self.mLuciq getTags]);
    [self waitForExpectations:@[expectation] timeout:5.0];
}


- (void)testAddFeatureFlags {
  NSDictionary *featureFlagsMap = @{ @"key13" : @"value1", @"key2" : @"value2"};
    FlutterError *error;

  [self.api addFeatureFlagsFeatureFlagsMap:featureFlagsMap error:&error];
  OCMVerify([self.mLuciq addFeatureFlags: [OCMArg checkWithBlock:^(id value) {
    NSArray<LCQFeatureFlag *> *featureFlags = value;
    NSString* firstFeatureFlagName = [featureFlags objectAtIndex:0 ].name;
    NSString* firstFeatureFlagKey = [[featureFlagsMap allKeys] objectAtIndex:0] ;
    if([ firstFeatureFlagKey isEqualToString: firstFeatureFlagName]){
      return YES;
    }
    return  NO;
  }]]);
}

- (void)testRemoveFeatureFlags {
  NSArray *featureFlags = @[@"exp1"];
    FlutterError *error;
    
  [self.api removeFeatureFlagsFeatureFlags:featureFlags error:&error];
    OCMVerify([self.mLuciq removeFeatureFlags: [OCMArg checkWithBlock:^(id value) {
      NSArray<LCQFeatureFlag *> *featureFlagsObJ = value;
      NSString* firstFeatureFlagName = [featureFlagsObJ objectAtIndex:0 ].name;
      NSString* firstFeatureFlagKey = [featureFlags firstObject] ;
      if([ firstFeatureFlagKey isEqualToString: firstFeatureFlagName]){
        return YES;
      }
      return  NO;
    }]]);}

- (void)testRemoveAllFeatureFlags {
    FlutterError *error;

  [self.api removeAllFeatureFlagsWithError:&error];
  OCMVerify([self.mLuciq removeAllFeatureFlags]);
}



- (void)testSetUserAttribute {
    NSString *key = @"is_premium";
    NSString *value = @"true";
    FlutterError *error;

    [self.api setUserAttributeValue:value key:key error:&error];

    OCMVerify([self.mLuciq setUserAttribute:value withKey:key]);
}

- (void)testRemoveUserAttribute {
    NSString *key = @"is_premium";
    FlutterError *error;

    [self.api removeUserAttributeKey:key error:&error];

    OCMVerify([self.mLuciq removeUserAttributeForKey:key]);
}

- (void)testGetUserAttributeForKey {
    NSString *key = @"is_premium";
    NSString *expected = @"yup";
    XCTestExpectation *expectation = [self expectationWithDescription:@"Call completion handler"];

    OCMStub([self.mLuciq userAttributeForKey:key]).andReturn(expected);

    [self.api getUserAttributeForKeyKey:key completion:^(NSString *actual, FlutterError *error) {
        [expectation fulfill];
        XCTAssertEqual(expected, actual);
    }];

    OCMVerify([self.mLuciq userAttributeForKey:key]);
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testGetUserAttributes {
    NSDictionary<NSString *, NSString *> *expected = @{ @"plan": @"hobby" };
    XCTestExpectation *expectation = [self expectationWithDescription:@"Call completion handler"];

    OCMStub([self.mLuciq userAttributes]).andReturn(expected);

    [self.api getUserAttributesWithCompletion:^(NSDictionary<NSString *, NSString *> *actual, FlutterError *error) {
        [expectation fulfill];
        XCTAssertEqual(expected, actual);
    }];

    OCMVerify([self.mLuciq userAttributes]);
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testSetReproStepsConfig {
    NSString *bugMode = @"ReproStepsMode.enabled";
    NSString *crashMode = @"ReproStepsMode.disabled";
    NSString *sessionReplayMode = @"ReproStepsMode.disabled";
    FlutterError *error;

    [self.api setReproStepsConfigBugMode:bugMode crashMode:crashMode sessionReplayMode:sessionReplayMode error:&error];

    OCMVerify([self.mLuciq setReproStepsFor:LCQIssueTypeBug withMode:LCQUserStepsModeEnable]);
    OCMVerify([self.mLuciq setReproStepsFor:LCQIssueTypeAllCrashes withMode:LCQUserStepsModeDisable]);
    OCMVerify([self.mLuciq setReproStepsFor:LCQIssueTypeSessionReplay withMode:LCQUserStepsModeDisable]);
}

- (void)testReportScreenChange {
    NSString *screenName = @"HomeScreen";
    FlutterError *error;

    [self.api reportScreenChangeScreenName:screenName error:&error];

    OCMVerify([self.mLuciq logViewDidAppearEvent:screenName]);
}

- (void)testSetCustomBrandingImage {
    NSString *lightImage = @"images/light_logo.jpeg";
    NSString *darkImage = @"images/dark_logo.jpeg";
    FlutterError *error;

    OCMStub([self.mApi getImageForAsset:[OCMArg isKindOfClass:[NSString class]]]).andReturn([UIImage new]);
    
    [self.api setCustomBrandingImageLight:lightImage dark:darkImage error:&error];

    OCMVerify([self.mLuciq setCustomBrandingImage:[OCMArg isKindOfClass:[UIImageAsset class]]]);
}

- (void)testSetFont {
    NSString* fontName = @"fonts/OpenSans-Regular.ttf";
    UIFont* font = [UIFont fontWithName:@"Open Sans" size:10.0];
    FlutterError *error;
    
    OCMStub([self.mApi getFontForAsset:fontName error:&error]).andReturn(font);

    [self.api setFontFont:fontName error:&error];

    OCMVerify([self.mLuciq setFont:font]);
}

- (void)testAddFileAttachmentWithURL {
    NSString *path = @"buggy.txt";
    NSString *name = @"Buggy";
    FlutterError *error;

    [self.api addFileAttachmentWithURLFilePath:path fileName:name error:&error];

    OCMVerify([self.mLuciq addFileAttachmentWithURL:[OCMArg isKindOfClass:[NSURL class]]]);
}

- (void)testAddFileAttachmentWithData {
    NSData *bytes = [NSData new];
    FlutterStandardTypedData *data = [FlutterStandardTypedData typedDataWithBytes:bytes];
    NSString *name = @"Issue";
    FlutterError *error;

    [self.api addFileAttachmentWithDataData:data fileName:name error:&error];

    OCMVerify([self.mLuciq addFileAttachmentWithData:[data data]]);
}

- (void)testClearFileAttachments {
    FlutterError *error;
    [self.api clearFileAttachmentsWithError:&error];

    OCMVerify([self.mLuciq clearFileAttachments]);
}

- (void)testNetworkLog {
    NSString *url = @"https://example.com";
    NSString *requestBody = @"hi";
    NSNumber *requestBodySize = @17;
    NSString *responseBody = @"{\"hello\":\"world\"}";
    NSNumber *responseBodySize = @153;
    NSString *method = @"POST";
    NSNumber *responseCode = @201;
    NSString *responseContentType = @"application/json";
    NSNumber *duration = @23000;
    NSNumber *startTime = @1670156107523;
    NSDictionary *requestHeaders = @{ @"Accepts": @"application/json" };
    NSDictionary *responseHeaders = @{ @"Content-Type": @"text/plain" };
    NSDictionary *data = @{
        @"url": url,
        @"requestBody": requestBody,
        @"requestBodySize": requestBodySize,
        @"responseBody": responseBody,
        @"responseBodySize": responseBodySize,
        @"method": method,
        @"responseCode": responseCode,
        @"requestHeaders": requestHeaders,
        @"responseHeaders": responseHeaders,
        @"responseContentType": responseContentType,
        @"duration": duration,
        @"startTime": startTime
    };
    FlutterError* error;

    [self.api networkLogData:data error:&error];
    
    OCMVerify([self.mNetworkLogger addNetworkLogWithUrl:url
                                                 method:method
                                            requestBody:requestBody
                                        requestBodySize:requestBodySize.integerValue
                                           responseBody:responseBody
                                       responseBodySize:responseBodySize.integerValue
                                           responseCode:(int32_t) responseCode.integerValue
                                         requestHeaders:requestHeaders
                                        responseHeaders:responseHeaders
                                            contentType:responseContentType
                                            errorDomain:nil
                                              errorCode:0
                                              startTime:startTime.integerValue * 1000
                                               duration:duration.integerValue
                                           gqlQueryName:nil
                                     serverErrorMessage:nil
                                          isW3cCaughted:nil
                                              partialID:nil
                                              timestamp:nil
                                generatedW3CTraceparent:nil
                                 caughtedW3CTraceparent:nil]);
}

- (void)testWillRedirectToAppStore {
    FlutterError *error;
    [self.api willRedirectToStoreWithError:&error];

    OCMVerify([self.mLuciq willRedirectToAppStore]);
}

- (void)testSetNetworkLogBodyEnabled {
    NSNumber *isEnabled = @1;
    FlutterError *error;

    [self.api setNetworkLogBodyEnabledIsEnabled:isEnabled error:&error];

    XCTAssertTrue(LCQNetworkLogger.logBodyEnabled);
}

- (void)testNetworkLogWithW3Caught {
    NSString *url = @"https://example.com";
    NSString *requestBody = @"hi";
    NSNumber *requestBodySize = @17;
    NSString *responseBody = @"{\"hello\":\"world\"}";
    NSNumber *responseBodySize = @153;
    NSString *method = @"POST";
    NSNumber *responseCode = @201;
    NSString *responseContentType = @"application/json";
    NSNumber *duration = @23000;
    NSNumber *startTime = @1670156107523;
    NSString *w3CCaughtHeader = @"1234";
    NSDictionary *requestHeaders = @{ @"Accepts": @"application/json",@"traceparent":w3CCaughtHeader};
    NSDictionary *responseHeaders = @{ @"Content-Type": @"text/plain" };
    NSDictionary *data = @{
            @"url": url,
            @"requestBody": requestBody,
            @"requestBodySize": requestBodySize,
            @"responseBody": responseBody,
            @"responseBodySize": responseBodySize,
            @"method": method,
            @"responseCode": responseCode,
            @"requestHeaders": requestHeaders,
            @"responseHeaders": responseHeaders,
            @"responseContentType": responseContentType,
            @"duration": duration,
            @"startTime": startTime,
            @"isW3cHeaderFound":@1,
            @"w3CCaughtHeader":w3CCaughtHeader
    };

    FlutterError* error;

    [self.api networkLogData:data error:&error];

    OCMVerify([self.mNetworkLogger addNetworkLogWithUrl:url
                                                 method:method
                                            requestBody:requestBody
                                        requestBodySize:requestBodySize.integerValue
                                           responseBody:responseBody
                                       responseBodySize:responseBodySize.integerValue
                                           responseCode:(int32_t) responseCode.integerValue
                                         requestHeaders:requestHeaders
                                        responseHeaders:responseHeaders
                                            contentType:responseContentType
                                            errorDomain:nil
                                              errorCode:0
                                              startTime:startTime.integerValue * 1000
                                               duration:duration.integerValue
                                           gqlQueryName:nil
                                     serverErrorMessage:nil
                                          isW3cCaughted:@1
                                              partialID:nil
                                              timestamp:nil
                                generatedW3CTraceparent:nil
                                 caughtedW3CTraceparent:@"1234"
              ]);
}

- (void)testNetworkLogWithW3GeneratedHeader {
    NSString *url = @"https://example.com";
    NSString *requestBody = @"hi";
    NSNumber *requestBodySize = @17;
    NSString *responseBody = @"{\"hello\":\"world\"}";
    NSNumber *responseBodySize = @153;
    NSString *method = @"POST";
    NSNumber *responseCode = @201;
    NSString *responseContentType = @"application/json";
    NSNumber *duration = @23000;
    NSNumber *startTime = @1670156107523;
    NSDictionary *requestHeaders = @{ @"Accepts": @"application/json" };
    NSDictionary *responseHeaders = @{ @"Content-Type": @"text/plain" };
    NSNumber *partialID = @12;

    NSNumber *timestamp = @34;

    NSString *generatedW3CTraceparent = @"12-34";

    NSString *caughtedW3CTraceparent = nil;
    NSDictionary *data = @{
            @"url": url,
            @"requestBody": requestBody,
            @"requestBodySize": requestBodySize,
            @"responseBody": responseBody,
            @"responseBodySize": responseBodySize,
            @"method": method,
            @"responseCode": responseCode,
            @"requestHeaders": requestHeaders,
            @"responseHeaders": responseHeaders,
            @"responseContentType": responseContentType,
            @"duration": duration,
            @"startTime": startTime,
            @"isW3cHeaderFound": @0,
            @"partialId": partialID,
            @"networkStartTimeInSeconds": timestamp,
            @"w3CGeneratedHeader": generatedW3CTraceparent,

    };
    NSNumber *isW3cCaughted = @0;

    FlutterError* error;

    [self.api networkLogData:data error:&error];

    OCMVerify([self.mNetworkLogger addNetworkLogWithUrl:url
                                                 method:method
                                            requestBody:requestBody
                                        requestBodySize:requestBodySize.integerValue
                                           responseBody:responseBody
                                       responseBodySize:responseBodySize.integerValue
                                           responseCode:(int32_t) responseCode.integerValue
                                         requestHeaders:requestHeaders
                                        responseHeaders:responseHeaders
                                            contentType:responseContentType
                                            errorDomain:nil
                                              errorCode:0
                                              startTime:startTime.integerValue * 1000
                                               duration:duration.integerValue
                                           gqlQueryName:nil
                                     serverErrorMessage:nil
                                          isW3cCaughted:isW3cCaughted
                                              partialID:partialID
                                              timestamp:timestamp
                                generatedW3CTraceparent:generatedW3CTraceparent
                                 caughtedW3CTraceparent:caughtedW3CTraceparent



              ]);
}

- (void)testisW3CFeatureFlagsEnabled {
    FlutterError *error;

    id mock = OCMClassMock([LCQNetworkLogger class]);
    NSNumber *isW3cExternalTraceIDEnabled = @(YES);

    OCMStub([mock w3ExternalTraceIDEnabled]).andReturn([isW3cExternalTraceIDEnabled boolValue]);
    OCMStub([mock w3ExternalGeneratedHeaderEnabled]).andReturn([isW3cExternalTraceIDEnabled boolValue]);
    OCMStub([mock w3CaughtHeaderEnabled]).andReturn([isW3cExternalTraceIDEnabled boolValue]);



    NSDictionary<NSString* , NSNumber *> * result= [self.api isW3CFeatureFlagsEnabledWithError:&error];

    XCTAssertEqual(result[@"isW3cExternalTraceIDEnabled"],isW3cExternalTraceIDEnabled);
    XCTAssertEqual(result[@"isW3cExternalGeneratedHeaderEnabled"],isW3cExternalTraceIDEnabled);
    XCTAssertEqual(result[@"isW3cCaughtHeaderEnabled"],isW3cExternalTraceIDEnabled);

}

- (void)testSetThemeWithAllProperties {
    NSDictionary *themeConfig = @{
        @"primaryColor": @"#FF6B6B",
        @"backgroundColor": @"#FFFFFF",
        @"titleTextColor": @"#000000",
        @"primaryTextColor": @"#333333",
        @"secondaryTextColor": @"#666666",
        @"callToActionTextColor": @"#FF6B6B",
        @"primaryFontPath": @"assets/fonts/CustomFont-Regular.ttf",
        @"secondaryFontPath": @"assets/fonts/CustomFont-Bold.ttf",
        @"ctaFontPath": @"assets/fonts/CustomFont-Italic.ttf"
    };

    id mockTheme = OCMClassMock([LCQTheme class]);
    OCMStub([mockTheme primaryColor]).andReturn([UIColor redColor]);
    OCMStub([mockTheme backgroundColor]).andReturn([UIColor whiteColor]);
    OCMStub([mockTheme titleTextColor]).andReturn([UIColor blackColor]);
    OCMStub([mockTheme primaryTextColor]).andReturn([UIColor darkGrayColor]);
    OCMStub([mockTheme secondaryTextColor]).andReturn([UIColor grayColor]);
    OCMStub([mockTheme callToActionTextColor]).andReturn([UIColor redColor]);

    FlutterError *error;

    [self.api setThemeThemeConfig:themeConfig error:&error];

    OCMVerify([self.mLuciq setTheme:[OCMArg isNotNil]]);
}

- (void)testSetFullscreen {
    NSNumber *isEnabled = @1;
    FlutterError *error;

    [self.api setFullscreenIsEnabled:isEnabled error:&error];

    // Since this is an empty implementation, we just verify the method can be called without error
    XCTAssertNil(error);
}
- (void)testSetEnableUserStepsIsEnabled{
    NSNumber *isEnabled = @1;
    FlutterError *error;

    [self.api setEnableUserStepsIsEnabled:isEnabled error:&error];

    OCMVerify([self.mLuciq setTrackUserSteps:YES]);

}

- (void)testLogUserStepsGestureType{
    NSString* message = @"message";
    NSString* view = @"viewName";
    FlutterError *error;

    [self.api logUserStepsGestureType:@"GestureType.tap" message:message viewName:view error: &error];

    XCTAssertNil(error, @"Error should be nil");

}
- (void)testAutoMasking {
    NSArray<NSString *> *autoMaskingTypes = @[@"AutoMasking.labels", @"AutoMasking.textInputs",@"AutoMasking.media",@"AutoMasking.none"];
    FlutterError *error;

    [self.api enableAutoMaskingAutoMasking:autoMaskingTypes error:&error];

    OCMVerify([self.mLuciq setAutoMaskScreenshots: (LCQAutoMaskScreenshotOptionMaskNothing | LCQAutoMaskScreenshotOptionTextInputs | LCQAutoMaskScreenshotOptionLabels | LCQAutoMaskScreenshotOptionMedia)]);
}
- (void)testGetNetworkBodyMaxSize {
    double expectedValue = 10240.0;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Call completion handler"];

    OCMStub([self.mNetworkLogger getNetworkBodyMaxSize]).andReturn(expectedValue);

    [self.api getNetworkBodyMaxSizeWithCompletion:^(NSNumber *actual, FlutterError *error) {
        [expectation fulfill];
        XCTAssertEqual(actual.doubleValue, expectedValue);
        XCTAssertNil(error);
    }];

    OCMVerify([self.mNetworkLogger getNetworkBodyMaxSize]);
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testSetNetworkAutoMaskingEnabled {
    NSNumber *isEnabled = @1;
    FlutterError *error;
    [self.api setNetworkAutoMaskingEnabledIsEnabled:isEnabled error:&error];

    OCMVerify([self.mNetworkLogger setAutoMaskingEnabled:YES]);
}

@end
