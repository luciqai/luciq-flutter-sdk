package ai.luciq.flutter.modules;

import androidx.annotation.NonNull;

import ai.luciq.flutter.generated.SurveysPigeon;
import ai.luciq.flutter.util.RunCatching;
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
        RunCatching.runCatching("SurveysApi.setEnabled", () -> {
            if (isEnabled) {
                Surveys.setState(Feature.State.ENABLED);
            } else {
                Surveys.setState(Feature.State.DISABLED);
            }
        });
    }

    @Override
    public void showSurveyIfAvailable() {
        RunCatching.runCatching("SurveysApi.showSurveyIfAvailable", Surveys::showSurveyIfAvailable);
    }

    @Override
    public void showSurvey(@NonNull String surveyToken) {
        RunCatching.runCatching("SurveysApi.showSurvey", () -> Surveys.showSurvey(surveyToken));
    }

    @Override
    public void setAutoShowingEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("SurveysApi.setAutoShowingEnabled", () -> Surveys.setAutoShowingEnabled(isEnabled));
    }

    @Override
    public void setShouldShowWelcomeScreen(@NonNull Boolean shouldShowWelcomeScreen) {
        RunCatching.runCatching("SurveysApi.setShouldShowWelcomeScreen", () -> Surveys.setShouldShowWelcomeScreen(shouldShowWelcomeScreen));
    }

    @Override
    public void setAppStoreURL(@NonNull String appStoreURL) {
        // iOS Only
    }

    @Override
    public void hasRespondedToSurvey(@NonNull String surveyToken, SurveysPigeon.Result<Boolean> result) {
        RunCatching.runCatching("SurveysApi.hasRespondedToSurvey", () -> {
            ThreadManager.runOnBackground(
                    new Runnable() {
                        @Override
                        public void run() {
                            final boolean hasResponded = RunCatching.runCatchingReturn(
                                    "SurveysApi.hasRespondedToSurvey.bg",
                                    false,
                                    () -> Surveys.hasRespondToSurvey(surveyToken)
                            );

                            ThreadManager.runOnMainThread(new Runnable() {
                                @Override
                                public void run() {
                                    result.success(hasResponded);
                                }
                            });
                        }
                    }
            );
        });
    }

    @Override
    public void getAvailableSurveys(SurveysPigeon.Result<List<String>> result) {
        RunCatching.runCatching("SurveysApi.getAvailableSurveys", () -> {
            ThreadManager.runOnBackground(
                    new Runnable() {
                        @Override
                        public void run() {
                            ArrayList<String> titles = RunCatching.runCatchingReturn(
                                    "SurveysApi.getAvailableSurveys.bg",
                                    new ArrayList<>(),
                                    () -> {
                                        List<Survey> surveys = Surveys.getAvailableSurveys();
                                        ArrayList<String> out = new ArrayList<>();
                                        for (Survey survey : surveys != null ? surveys : new ArrayList<Survey>()) {
                                            out.add(survey.getTitle());
                                        }
                                        return out;
                                    }
                            );

                            ThreadManager.runOnMainThread(new Runnable() {
                                @Override
                                public void run() {
                                    result.success(titles);
                                }
                            });
                        }
                    }
            );
        });
    }

    @Override
    public void bindOnShowSurveyCallback() {
        RunCatching.runCatching("SurveysApi.bindOnShowSurveyCallback", () -> {
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
        });
    }

    @Override
    public void bindOnDismissSurveyCallback() {
        RunCatching.runCatching("SurveysApi.bindOnDismissSurveyCallback", () -> {
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
        });
    }
}
