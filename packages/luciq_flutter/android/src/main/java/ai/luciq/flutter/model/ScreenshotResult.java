package ai.luciq.flutter.model;

import android.graphics.Bitmap;

public class ScreenshotResult {
    private final float pixelRatio;
    private final Bitmap screenshot;
    private final float offsetX;
    private final float offsetY;

    public ScreenshotResult(float pixelRatio, Bitmap screenshot) {
        this(pixelRatio, screenshot, 0, 0);
    }

    public ScreenshotResult(float pixelRatio, Bitmap screenshot, float offsetX, float offsetY) {
        this.pixelRatio = pixelRatio;
        this.screenshot = screenshot;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
    }

    public Bitmap getScreenshot() {
        return screenshot;
    }

    public float getPixelRatio() {
        return pixelRatio;
    }

    public float getOffsetX() {
        return offsetX;
    }

    public float getOffsetY() {
        return offsetY;
    }
}
