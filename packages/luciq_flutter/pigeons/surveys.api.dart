import 'package:pigeon/pigeon.dart';

@FlutterApi()
abstract class SurveysFlutterApi {
  void onShowSurvey(String callId);
  void onDismissSurvey(String callId);
}

@HostApi()
abstract class SurveysHostApi {
  void setEnabled(bool isEnabled);
  void showSurveyIfAvailable();
  void showSurvey(String callId, String surveyToken);
  void setAutoShowingEnabled(bool isEnabled);
  void setShouldShowWelcomeScreen(bool shouldShowWelcomeScreen);
  void setAppStoreURL(String appStoreURL);

  @async
  bool hasRespondedToSurvey(String callId, String surveyToken);

  @async
  List<String> getAvailableSurveys(String callId);

  void bindOnShowSurveyCallback();
  void bindOnDismissSurveyCallback();
}
