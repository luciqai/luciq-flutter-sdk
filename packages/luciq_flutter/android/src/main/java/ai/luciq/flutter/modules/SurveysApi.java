package ai.luciq.flutter.modules;

import androidx.annotation.NonNull;

import ai.luciq.flutter.generated.SurveysPigeon;
import ai.luciq.flutter.util.LuciqFlutterDebugTags;
import ai.luciq.flutter.util.LuciqFlutterLogger;
import ai.luciq.flutter.util.ThreadManager;
import ai.luciq.library.Feature;
import ai.luciq.survey.Survey;
import ai.luciq.survey.Surveys;
import ai.luciq.survey.callbacks.OnDismissCallback;
import ai.luciq.survey.callbacks.OnShowCallback;

import java.util.ArrayList;
import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;

public class SurveysApi implements SurveysPigeon.SurveysHostApi {
    private final SurveysPigeon.SurveysFlutterApi flutterApi;

    public static void init(BinaryMessenger messenger) {
        final SurveysPigeon.SurveysFlutterApi flutterApi = new SurveysPigeon.SurveysFlutterApi(messenger);
        final SurveysApi api = new SurveysApi(flutterApi);
        SurveysPigeon.SurveysHostApi.setup(messenger, api);
    }

    public SurveysApi(SurveysPigeon.SurveysFlutterApi flutterApi) {
        this.flutterApi = flutterApi;
    }

    @Override
    public void setEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS, "[setEnabled] isEnabled=" + isEnabled);
        if (isEnabled) {
            Surveys.setState(Feature.State.ENABLED);
        } else {
            Surveys.setState(Feature.State.DISABLED);
        }
    }

    @Override
    public void showSurveyIfAvailable() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS, "[showSurveyIfAvailable]");
        Surveys.showSurveyIfAvailable();
    }

    @Override
    public void showSurvey(@NonNull String surveyToken) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[showSurvey] surveyTokenPresent=" + (surveyToken != null && !surveyToken.isEmpty()));
        Surveys.showSurvey(surveyToken);
    }

    @Override
    public void setAutoShowingEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS, "[setAutoShowingEnabled] isEnabled=" + isEnabled);
        Surveys.setAutoShowingEnabled(isEnabled);
    }

    @Override
    public void setShouldShowWelcomeScreen(@NonNull Boolean shouldShowWelcomeScreen) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[setShouldShowWelcomeScreen] shouldShowWelcomeScreen=" + shouldShowWelcomeScreen);
        Surveys.setShouldShowWelcomeScreen(shouldShowWelcomeScreen);
    }

    @Override
    public void setAppStoreURL(@NonNull String appStoreURL) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[setAppStoreURL] url=" + LuciqFlutterLogger.redactUrl(appStoreURL));
        // iOS Only
    }

    @Override
    public void hasRespondedToSurvey(@NonNull String surveyToken, SurveysPigeon.Result<Boolean> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[hasRespondedToSurvey] surveyTokenPresent=" + (surveyToken != null && !surveyToken.isEmpty()));
        ThreadManager.runOnBackground(
                new Runnable() {
                    @Override
                    public void run() {
                        final boolean hasResponded = Surveys.hasRespondToSurvey(surveyToken);

                        ThreadManager.runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                result.success(hasResponded);
                            }
                        });
                    }
                }
        );
    }

    @Override
    public void getAvailableSurveys(SurveysPigeon.Result<List<String>> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS, "[getAvailableSurveys]");
        ThreadManager.runOnBackground(
                new Runnable() {
                    @Override
                    public void run() {
                        List<Survey> surveys = Surveys.getAvailableSurveys();

                        ArrayList<String> titles = new ArrayList<>();
                        for (Survey survey : surveys != null ? surveys : new ArrayList<Survey>()) {
                            titles.add(survey.getTitle());
                        }

                        ThreadManager.runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                result.success(titles);
                            }
                        });
                    }
                }
        );
    }

    @Override
    public void bindOnShowSurveyCallback() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS, "[bindOnShowSurveyCallback]");
        Surveys.setOnShowCallback(new OnShowCallback() {
            @Override
            public void onShow() {
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        flutterApi.onShowSurvey(new SurveysPigeon.SurveysFlutterApi.Reply<Void>() {
                            @Override
                            public void reply(Void reply) {
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void bindOnDismissSurveyCallback() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS, "[bindOnDismissSurveyCallback]");
        Surveys.setOnDismissCallback(new OnDismissCallback() {
            @Override
            public void onDismiss() {
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        flutterApi.onDismissSurvey(new SurveysPigeon.SurveysFlutterApi.Reply<Void>() {
                            @Override
                            public void reply(Void reply) {
                            }
                        });
                    }
                });
            }
        });
    }
}
