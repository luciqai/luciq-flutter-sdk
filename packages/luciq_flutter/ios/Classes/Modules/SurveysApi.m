#import <Flutter/Flutter.h>
#import "LuciqSDK/LuciqSDK.h"
#import "SurveysApi.h"
#import "../Util/LCQRunCatching.h"

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
    LCQRunCatching(@"SurveysApi.setEnabled", ^{
        LCQSurveys.enabled = [isEnabled boolValue];
    });
}

- (void)showSurveyIfAvailableWithError:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"SurveysApi.showSurveyIfAvailable", ^{
        [LCQSurveys showSurveyIfAvailable];
    });
}

- (void)showSurveySurveyToken:(NSString *)surveyToken error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"SurveysApi.showSurvey", ^{
        [LCQSurveys showSurveyWithToken:surveyToken];
    });
}

- (void)setAutoShowingEnabledIsEnabled:(NSNumber *)isEnabled error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"SurveysApi.setAutoShowingEnabled", ^{
        LCQSurveys.autoShowingEnabled = [isEnabled boolValue];
    });
}

- (void)setShouldShowWelcomeScreenShouldShowWelcomeScreen:(NSNumber *)shouldShowWelcomeScreen error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"SurveysApi.setShouldShowWelcomeScreen", ^{
        LCQSurveys.shouldShowWelcomeScreen = [shouldShowWelcomeScreen boolValue];
    });
}

- (void)setAppStoreURLAppStoreURL:(NSString *)appStoreURL error:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"SurveysApi.setAppStoreURL", ^{
        LCQSurveys.appStoreURL = appStoreURL;
    });
}

- (void)hasRespondedToSurveySurveyToken:(NSString *)surveyToken completion:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion {
    LCQRunCatching(@"SurveysApi.hasRespondedToSurvey", ^{
        [LCQSurveys hasRespondedToSurveyWithToken:surveyToken
                                completionHandler:^(BOOL hasResponded) {
                                    NSNumber *boolNumber = [NSNumber numberWithBool:hasResponded];
                                    completion(boolNumber, nil);
                                }];
    });
}

- (void)getAvailableSurveysWithCompletion:(void (^)(NSArray<NSString *> *_Nullable, FlutterError *_Nullable))completion {
    LCQRunCatching(@"SurveysApi.getAvailableSurveys", ^{
        [LCQSurveys availableSurveysWithCompletionHandler:^(NSArray<LCQSurvey *> *availableSurveys) {
            NSMutableArray<NSString *> *titles = [[NSMutableArray alloc] init];
            for (LCQSurvey *survey in availableSurveys) {
                [titles addObject:[survey title]];
            }
            completion(titles, nil);
        }];
    });
}

- (void)bindOnShowSurveyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"SurveysApi.bindOnShowSurveyCallback", ^{
        LCQSurveys.willShowSurveyHandler = ^{
            [self->_flutterApi onShowSurveyWithCompletion:^(FlutterError *_Nullable _){}];
        };
    });
}

- (void)bindOnDismissSurveyCallbackWithError:(FlutterError *_Nullable *_Nonnull)error {
    LCQRunCatching(@"SurveysApi.bindOnDismissSurveyCallback", ^{
        LCQSurveys.didDismissSurveyHandler = ^{
            [self->_flutterApi onDismissSurveyWithCompletion:^(FlutterError *_Nullable _){}];
        };
    });
}

@end
