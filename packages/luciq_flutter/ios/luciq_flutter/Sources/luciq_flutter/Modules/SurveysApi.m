#import <Flutter/Flutter.h>
#import "LuciqSDK/LuciqSDK.h"
#import "SurveysApi.h"

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
    BOOL boolValue = [isEnabled boolValue];
    LCQSurveys.enabled = boolValue;
}

- (void)showSurveyIfAvailableWithError:(FlutterError *_Nullable *_Nonnull)error {
    [LCQSurveys showSurveyIfAvailable];
}

- (void)showSurveySurveyToken:(NSString *)surveyToken error:(FlutterError *_Nullable *_Nonnull)error {
    [LCQSurveys showSurveyWithToken:surveyToken];
}

- (void)setAutoShowingEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    BOOL boolValue = [isEnabled boolValue];
    LCQSurveys.autoShowingEnabled = boolValue;
}

- (void)setShouldShowWelcomeScreenShouldShowWelcomeScreen:(NSNumber *)shouldShowWelcomeScreen error:(FlutterError *_Nullable *_Nonnull)error {
    BOOL boolValue = [shouldShowWelcomeScreen boolValue];
    LCQSurveys.shouldShowWelcomeScreen = boolValue;
}

- (void)setAppStoreURLAppStoreURL:(NSString *)appStoreURL error:(FlutterError *_Nullable *_Nonnull)error {
    LCQSurveys.appStoreURL = appStoreURL;
}

- (void)hasRespondedToSurveySurveyToken:(NSString *)surveyToken completion:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion {
    [LCQSurveys hasRespondedToSurveyWithToken:surveyToken
                            completionHandler:^(BOOL hasResponded) {
                              NSNumber *boolNumber = [NSNumber numberWithBool:hasResponded];
                              completion(boolNumber, nil);
                            }];
}

- (void)getAvailableSurveysWithCompletion:(void (^)(NSArray<NSString *> *_Nullable, FlutterError *_Nullable))completion {
    [LCQSurveys availableSurveysWithCompletionHandler:^(NSArray<LCQSurvey *> *availableSurveys) {
      NSMutableArray<NSString *> *titles = [[NSMutableArray alloc] init];

      for (LCQSurvey *survey in availableSurveys) {
          [titles addObject:[survey title]];
      }

      completion(titles, nil);
    }];
}

- (void)bindOnShowSurveyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    LCQSurveys.willShowSurveyHandler = ^{
      [self->_flutterApi onShowSurveyWithCompletion:^(FlutterError *_Nullable _){
      }];
    };
}

- (void)bindOnDismissSurveyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    LCQSurveys.didDismissSurveyHandler = ^{
      [self->_flutterApi onDismissSurveyWithCompletion:^(FlutterError *_Nullable _){
      }];
    };
}

@end
