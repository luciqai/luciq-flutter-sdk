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
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[Surveys.setEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    BOOL boolValue = [isEnabled boolValue];
    LCQSurveys.enabled = boolValue;
}

- (void)showSurveyIfAvailableWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[Surveys.showSurveyIfAvailable]"];
    [LCQSurveys showSurveyIfAvailable];
}

- (void)showSurveySurveyToken:(NSString *)surveyToken error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[Surveys.showSurvey] tokenPresent=%@ length=%lu", (surveyToken.length > 0 ? @"YES" : @"NO"), (unsigned long)surveyToken.length];
    [LCQSurveys showSurveyWithToken:surveyToken];
}

- (void)setAutoShowingEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[Surveys.setAutoShowingEnabled] isEnabled=%@", ([isEnabled boolValue] ? @"YES" : @"NO")];
    BOOL boolValue = [isEnabled boolValue];
    LCQSurveys.autoShowingEnabled = boolValue;
}

- (void)setShouldShowWelcomeScreenShouldShowWelcomeScreen:(NSNumber *)shouldShowWelcomeScreen error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[Surveys.setShouldShowWelcomeScreen] shouldShow=%@", ([shouldShowWelcomeScreen boolValue] ? @"YES" : @"NO")];
    BOOL boolValue = [shouldShowWelcomeScreen boolValue];
    LCQSurveys.shouldShowWelcomeScreen = boolValue;
}

- (void)setAppStoreURLAppStoreURL:(NSString *)appStoreURL error:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[Surveys.setAppStoreURL] url=%@", [LuciqFlutterLogger redactURL:appStoreURL]];
    LCQSurveys.appStoreURL = appStoreURL;
}

- (void)hasRespondedToSurveySurveyToken:(NSString *)surveyToken completion:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[Surveys.hasRespondedToSurvey] tokenLength=%lu", (unsigned long)surveyToken.length];
    [LCQSurveys hasRespondedToSurveyWithToken:surveyToken
                            completionHandler:^(BOOL hasResponded) {
                              NSNumber *boolNumber = [NSNumber numberWithBool:hasResponded];
                              completion(boolNumber, nil);
                            }];
}

- (void)getAvailableSurveysWithCompletion:(void (^)(NSArray<NSString *> *_Nullable, FlutterError *_Nullable))completion {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[Surveys.getAvailableSurveys]"];
    [LCQSurveys availableSurveysWithCompletionHandler:^(NSArray<LCQSurvey *> *availableSurveys) {
      NSMutableArray<NSString *> *titles = [[NSMutableArray alloc] init];

      for (LCQSurvey *survey in availableSurveys) {
          [titles addObject:[survey title]];
      }

      completion(titles, nil);
    }];
}

- (void)bindOnShowSurveyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[Surveys.bindOnShowSurveyCallback]"];
    LCQSurveys.willShowSurveyHandler = ^{
      [self->_flutterApi onShowSurveyWithCompletion:^(FlutterError *_Nullable _){
      }];
    };
}

- (void)bindOnDismissSurveyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags surveys] format:@"[Surveys.bindOnDismissSurveyCallback]"];
    LCQSurveys.didDismissSurveyHandler = ^{
      [self->_flutterApi onDismissSurveyWithCompletion:^(FlutterError *_Nullable _){
      }];
    };
}

@end
