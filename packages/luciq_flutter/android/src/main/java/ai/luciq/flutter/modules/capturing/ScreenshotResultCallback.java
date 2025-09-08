package ai.luciq.flutter.modules.capturing;


import ai.luciq.flutter.model.ScreenshotResult;

public interface ScreenshotResultCallback {
    void onScreenshotResult(ScreenshotResult screenshotResult);
    void onError();
}
