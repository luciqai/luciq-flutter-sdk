package ai.luciq.flutter.modules;

import androidx.annotation.NonNull;

import ai.luciq.chat.Replies;
import ai.luciq.flutter.generated.RepliesPigeon;
import ai.luciq.flutter.util.RunCatching;
import ai.luciq.flutter.util.ThreadManager;
import ai.luciq.library.Feature;

import io.flutter.plugin.common.BinaryMessenger;

public class RepliesApi implements RepliesPigeon.RepliesHostApi {
    private final RepliesPigeon.RepliesFlutterApi flutterApi;

    public static void init(BinaryMessenger messenger) {
        final RepliesPigeon.RepliesFlutterApi flutterApi = new RepliesPigeon.RepliesFlutterApi(messenger);
        final RepliesApi api = new RepliesApi(flutterApi);
        RepliesPigeon.RepliesHostApi.setup(messenger, api);
    }

    public RepliesApi(RepliesPigeon.RepliesFlutterApi flutterApi) {
        this.flutterApi = flutterApi;
    }

    @Override
    public void setEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("RepliesApi.setEnabled", () -> {
            if (isEnabled) {
                Replies.setState(Feature.State.ENABLED);
            } else {
                Replies.setState(Feature.State.DISABLED);
            }
        });
    }

    @Override
    public void show() {
        RunCatching.runCatching("RepliesApi.show", Replies::show);
    }

    @Override
    public void setInAppNotificationsEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("RepliesApi.setInAppNotificationsEnabled",
                () -> Replies.setInAppNotificationEnabled(isEnabled));
    }

    @Override
    public void setInAppNotificationSound(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("RepliesApi.setInAppNotificationSound",
                () -> Replies.setInAppNotificationSound(isEnabled));
    }

    @Override
    public void getUnreadRepliesCount(RepliesPigeon.Result<Long> result) {
        RunCatching.runCatching("RepliesApi.getUnreadRepliesCount", () -> {
            ThreadManager.runOnBackground(
                    new Runnable() {
                        @Override
                        public void run() {
                            final long count = RunCatching.runCatchingReturn(
                                    "RepliesApi.getUnreadRepliesCount.bg",
                                    -1,
                                    Replies::getUnreadRepliesCount
                            );

                            ThreadManager.runOnMainThread(new Runnable() {
                                @Override
                                public void run() {
                                    result.success(count);
                                }
                            });
                        }
                    }
            );
        });
    }

    @Override
    public void hasChats(RepliesPigeon.Result<Boolean> result) {
        RunCatching.runCatching("RepliesApi.hasChats", () -> {
            ThreadManager.runOnBackground(
                    new Runnable() {
                        @Override
                        public void run() {
                            final boolean hasChats = RunCatching.runCatchingReturn(
                                    "RepliesApi.hasChats.bg",
                                    false,
                                    Replies::hasChats
                            );

                            ThreadManager.runOnMainThread(new Runnable() {
                                @Override
                                public void run() {
                                    result.success(hasChats);
                                }
                            });
                        }
                    }
            );
        });
    }

    @Override
    public void bindOnNewReplyCallback() {
        RunCatching.runCatching("RepliesApi.bindOnNewReplyCallback", () -> {
            Replies.setOnNewReplyReceivedCallback(new Runnable() {
                @Override
                public void run() {
                    ThreadManager.runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            flutterApi.onNewReply(new RepliesPigeon.RepliesFlutterApi.Reply<Void>() {
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
