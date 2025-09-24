package ai.luciq.flutter.util;

import ai.luciq.flutter.generated.ApmPigeon;
import ai.luciq.flutter.generated.LuciqPigeon;
import ai.luciq.flutter.generated.RepliesPigeon;
import ai.luciq.flutter.generated.SurveysPigeon;

interface Result<T> extends ApmPigeon.Result<T>, LuciqPigeon.Result<T>, RepliesPigeon.Result<T>, SurveysPigeon.Result<T> {
    void success(T result);

    void error(Throwable error);
}

public class MockResult {
    public static <T> Result<T> makeResult(Callback<T> success, Callback<Throwable> error) {
        return new Result<T>() {
            @Override
            public void success(T result) {
                success.callback(result);
            }

            @Override
            public void error(Throwable exception) {
                error.callback(exception);
            }
        };
    }

    public static <T> Result<T> makeResult(Callback<T> success) {
        return makeResult(success, (Throwable) -> {});
    }

    public static <T> Result<T> makeResult() {
        return makeResult((T) -> {}, (Throwable) -> {});
    }
}
