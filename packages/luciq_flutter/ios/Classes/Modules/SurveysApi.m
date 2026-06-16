#import <Flutter/Flutter.h>
#import "LuciqSDK/LuciqSDK.h"
#import "SurveysApi.h"
#import "../Util/LuciqFlutterLogger.h"
#import "../Util/LuciqFlutterDebugTags.h"

extern void InitSurveysApi(id<FlutterBinaryMessenger> messenger) {
    SurveysFlutterApi *flutterApi = [[SurveysFlutterApi alloc] initWithBinaryMessenger:messenger];
    SurveysApi *api = [[SurveysApi alloc] initWithFlutterApi:flutterApi];
    SurveysHostApiSetup(messenger, api);
}

@implementation SurveysApi

- (instancetype)initWithFlutterApi:(SurveysFlutterApi *)api {
    self = [super init];
    self.flutterApi = api;
    return self;
}

- (void)setEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                   format:@"[SUR.setEnabled] phase=enter isEnabled=%@",
        ([isEnabled boolValue] ? @"true" : @"false")];
    BOOL boolValue = [isEnabled boolValue];
    LCQSurveys.enabled = boolValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[SUR.setEnabled] phase=exit"];
}

- (void)showSurveyIfAvailableWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                   format:@"[SUR.showSurveyIfAvailable] phase=enter"];
    [LCQSurveys showSurveyIfAvailable];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[SUR.showSurveyIfAvailable] phase=exit"];
}

- (void)showSurveyCallId:(NSString *)callId surveyToken:(NSString *)surveyToken error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                   format:@"[SUR.showSurvey] #%@ phase=enter tokenPresent=%@ tokenLength=%lu",
        callId,
        (surveyToken.length > 0 ? @"true" : @"false"),
        (unsigned long)surveyToken.length];
    [LCQSurveys showSurveyWithToken:surveyToken];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[SUR.showSurvey] #%@ phase=exit", callId];
}

- (void)setAutoShowingEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                   format:@"[SUR.setAutoShowingEnabled] phase=enter isEnabled=%@",
        ([isEnabled boolValue] ? @"true" : @"false")];
    BOOL boolValue = [isEnabled boolValue];
    LCQSurveys.autoShowingEnabled = boolValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[SUR.setAutoShowingEnabled] phase=exit"];
}

- (void)setShouldShowWelcomeScreenShouldShowWelcomeScreen:(NSNumber *)shouldShowWelcomeScreen error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                   format:@"[SUR.setShouldShowWelcomeScreen] phase=enter shouldShow=%@",
        ([shouldShowWelcomeScreen boolValue] ? @"true" : @"false")];
    BOOL boolValue = [shouldShowWelcomeScreen boolValue];
    LCQSurveys.shouldShowWelcomeScreen = boolValue;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[SUR.setShouldShowWelcomeScreen] phase=exit"];
}

- (void)setAppStoreURLAppStoreURL:(NSString *)appStoreURL error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                   format:@"[SUR.setAppStoreURL] phase=enter url=%@",
        [LuciqFlutterLogger redactURL:appStoreURL]];
    LCQSurveys.appStoreURL = appStoreURL;
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[SUR.setAppStoreURL] phase=exit"];
}

- (void)hasRespondedToSurveyCallId:(NSString *)callId surveyToken:(NSString *)surveyToken completion:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                   format:@"[SUR.hasRespondedToSurvey] #%@ phase=enter tokenLength=%lu",
        callId, (unsigned long)surveyToken.length];
    [LCQSurveys hasRespondedToSurveyWithToken:surveyToken
                            completionHandler:^(BOOL hasResponded) {
                              NSNumber *boolNumber = [NSNumber numberWithBool:hasResponded];
                              [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                                             format:@"[SUR.hasRespondedToSurvey] #%@ phase=exit result=%@",
                                  callId,
                                  (hasResponded ? @"true" : @"false")];
                              completion(boolNumber, nil);
                            }];
}

- (void)getAvailableSurveysCallId:(NSString *)callId completion:(void (^)(NSArray<NSString *> *_Nullable, FlutterError *_Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                   format:@"[SUR.getAvailableSurveys] #%@ phase=enter", callId];
    [LCQSurveys availableSurveysWithCompletionHandler:^(NSArray<LCQSurvey *> *availableSurveys) {
      NSMutableArray<NSString *> *titles = [[NSMutableArray alloc] init];

      for (LCQSurvey *survey in availableSurveys) {
          [titles addObject:[survey title]];
      }

      [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                     format:@"[SUR.getAvailableSurveys] #%@ phase=exit resultCount=%lu",
          callId,
          (unsigned long)titles.count];
      completion(titles, nil);
    }];
}

- (void)bindOnShowSurveyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                   format:@"[SUR.bindOnShowSurveyCallback] phase=enter"];
    LCQSurveys.willShowSurveyHandler = ^{
      NSString *callId = [LuciqFlutterLogger nextCallId];
      [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                     format:@"[SUR.onShowSurvey] #%@ phase=fire", callId];
      [self->_flutterApi onShowSurveyCallId:callId completion:^(FlutterError *_Nullable _){
      }];
    };
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[SUR.bindOnShowSurveyCallback] phase=exit"];
}

- (void)bindOnDismissSurveyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                   format:@"[SUR.bindOnDismissSurveyCallback] phase=enter"];
    LCQSurveys.didDismissSurveyHandler = ^{
      NSString *callId = [LuciqFlutterLogger nextCallId];
      [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys]
                     format:@"[SUR.onDismissSurvey] #%@ phase=fire", callId];
      [self->_flutterApi onDismissSurveyCallId:callId completion:^(FlutterError *_Nullable _){
      }];
    };
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[SUR.bindOnDismissSurveyCallback] phase=exit"];
}

@end
