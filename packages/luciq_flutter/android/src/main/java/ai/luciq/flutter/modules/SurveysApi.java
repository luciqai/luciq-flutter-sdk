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
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.setEnabled] phase=enter isEnabled=" + isEnabled);
        if (isEnabled) {
            Surveys.setState(Feature.State.ENABLED);
        } else {
            Surveys.setState(Feature.State.DISABLED);
        }
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.setEnabled] phase=exit");
    }

    @Override
    public void showSurveyIfAvailable() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.showSurveyIfAvailable] phase=enter");
        Surveys.showSurveyIfAvailable();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.showSurveyIfAvailable] phase=exit");
    }

    @Override
    public void showSurvey(@NonNull String callId, @NonNull String surveyToken) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.showSurvey] #" + callId + " phase=enter surveyTokenPresent=" + (surveyToken != null && !surveyToken.isEmpty()));
        Surveys.showSurvey(surveyToken);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.showSurvey] #" + callId + " phase=exit");
    }

    @Override
    public void setAutoShowingEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.setAutoShowingEnabled] phase=enter isEnabled=" + isEnabled);
        Surveys.setAutoShowingEnabled(isEnabled);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.setAutoShowingEnabled] phase=exit");
    }

    @Override
    public void setShouldShowWelcomeScreen(@NonNull Boolean shouldShowWelcomeScreen) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.setShouldShowWelcomeScreen] phase=enter shouldShowWelcomeScreen=" + shouldShowWelcomeScreen);
        Surveys.setShouldShowWelcomeScreen(shouldShowWelcomeScreen);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.setShouldShowWelcomeScreen] phase=exit");
    }

    @Override
    public void setAppStoreURL(@NonNull String appStoreURL) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.setAppStoreURL] phase=enter url=" + LuciqFlutterLogger.redactUrl(appStoreURL));
        // iOS Only
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.setAppStoreURL] phase=exit");
    }

    @Override
    public void hasRespondedToSurvey(@NonNull String callId, @NonNull String surveyToken, SurveysPigeon.Result<Boolean> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.hasRespondedToSurvey] #" + callId + " phase=enter surveyTokenPresent=" + (surveyToken != null && !surveyToken.isEmpty()));
        ThreadManager.runOnBackground(
                new Runnable() {
                    @Override
                    public void run() {
                        final boolean hasResponded = Surveys.hasRespondToSurvey(surveyToken);

                        ThreadManager.runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                                        "[SUR.hasRespondedToSurvey] #" + callId + " phase=exit result=" + hasResponded);
                                result.success(hasResponded);
                            }
                        });
                    }
                }
        );
    }

    @Override
    public void getAvailableSurveys(@NonNull String callId, SurveysPigeon.Result<List<String>> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.getAvailableSurveys] #" + callId + " phase=enter");
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
                                LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                                        "[SUR.getAvailableSurveys] #" + callId + " phase=exit resultCount=" + titles.size());
                                result.success(titles);
                            }
                        });
                    }
                }
        );
    }

    @Override
    public void bindOnShowSurveyCallback() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.bindOnShowSurveyCallback] phase=enter");
        Surveys.setOnShowCallback(new OnShowCallback() {
            @Override
            public void onShow() {
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        String callId = LuciqFlutterLogger.nextCallId();
                        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                                "[SUR.onShowSurvey] #" + callId + " phase=fire");
                        flutterApi.onShowSurvey(callId, new SurveysPigeon.SurveysFlutterApi.Reply<Void>() {
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
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                "[SUR.bindOnDismissSurveyCallback] phase=enter");
        Surveys.setOnDismissCallback(new OnDismissCallback() {
            @Override
            public void onDismiss() {
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        String callId = LuciqFlutterLogger.nextCallId();
                        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SURVEYS,
                                "[SUR.onDismissSurvey] #" + callId + " phase=fire");
                        flutterApi.onDismissSurvey(callId, new SurveysPigeon.SurveysFlutterApi.Reply<Void>() {
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
