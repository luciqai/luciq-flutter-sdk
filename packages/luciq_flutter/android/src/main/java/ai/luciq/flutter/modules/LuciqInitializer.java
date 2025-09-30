package ai.luciq.flutter.modules;

import android.app.Application;
import android.util.Log;

import androidx.annotation.VisibleForTesting;

import ai.luciq.flutter.util.Reflection;
import ai.luciq.library.Luciq;
import ai.luciq.library.Platform;
import ai.luciq.library.invocation.LuciqInvocationEvent;

import java.lang.reflect.Method;

public class LuciqInitializer {
    private final String TAG = LuciqApi.class.getName();
    private static LuciqInitializer instance;

    private LuciqInitializer() {}

    public static LuciqInitializer getInstance() {
        if (instance == null) {
            synchronized (LuciqInitializer.class) {
                if (instance == null) {
                    instance = new LuciqInitializer();
                }
            }
        }
        return instance;
    }

    @VisibleForTesting
    public void setCurrentPlatform() {
        try {
            Method method = Reflection.getMethod(Class.forName("ai.luciq.library.Luciq"), "setCurrentPlatform", int.class);
            if (method != null) {
                method.invoke(null, Platform.FLUTTER);
            } else {
                Log.e(TAG, "setCurrentPlatform was not found by reflection");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error setting current platform", e);
        }
    }

    public static class Builder {
        /**
         * Application instance to initialize Luciq.
         */
        private Application application;

        /**
         * The application token obtained from the Luciq dashboard.
         */
        private String applicationToken;

        /**
         * The level of detail in logs that you want to print.
         */
        private int logLevel;

        /**
         * The events that trigger the SDK's user interface.
         */
        private LuciqInvocationEvent[] invocationEvents;
        private String appVariant;

        /**
         * Initialize Luciq SDK with application token and invocation trigger events
         *
         * @param application      Application object for initialization of library
         * @param applicationToken The app's identifying token, available on your dashboard.
         * @param invocationEvents The events that trigger the SDK's user interface.
         *                         <p>Choose from the available events listed in {@link LuciqInvocationEvent}.</p>
         */
        public Builder(Application application, String applicationToken, int logLevel, LuciqInvocationEvent... invocationEvents) {
            this.application = application;
            this.applicationToken = applicationToken;
            this.logLevel = logLevel;
            this.invocationEvents = invocationEvents;
        }

        public void build() {
            try {
                LuciqInitializer.getInstance().setCurrentPlatform();

                Luciq.Builder luciqBuilder = new Luciq.Builder(application, applicationToken, invocationEvents)
                        .setSdkDebugLogsLevel(logLevel);

                if(appVariant!=null){
                    luciqBuilder.setAppVariant(appVariant);
                }
                luciqBuilder.build();
            } catch (Exception e) {
                Log.e(LuciqInitializer.instance.TAG, "Error building Luciq", e);
            }
        }

        public void setAppVariant(String appVariant) {
            this.appVariant = appVariant;
        }
    }
}