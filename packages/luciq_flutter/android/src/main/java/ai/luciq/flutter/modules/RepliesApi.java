package ai.luciq.flutter.modules;

import androidx.annotation.NonNull;

import ai.luciq.chat.Replies;
import ai.luciq.flutter.generated.RepliesPigeon;
import ai.luciq.flutter.util.LuciqFlutterDebugTags;
import ai.luciq.flutter.util.LuciqFlutterLogger;
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
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.setEnabled] phase=enter isEnabled=" + isEnabled);
        if (isEnabled) {
            Replies.setState(Feature.State.ENABLED);
        } else {
            Replies.setState(Feature.State.DISABLED);
        }
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.setEnabled] phase=exit");
    }

    @Override
    public void show(@NonNull String callId) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.show] #" + callId + " phase=enter");
        Replies.show();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.show] #" + callId + " phase=exit");
    }

    @Override
    public void setInAppNotificationsEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.setInAppNotificationsEnabled] phase=enter isEnabled=" + isEnabled);
        Replies.setInAppNotificationEnabled(isEnabled);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.setInAppNotificationsEnabled] phase=exit");
    }

    @Override
    public void setInAppNotificationSound(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.setInAppNotificationSound] phase=enter isEnabled=" + isEnabled);
        Replies.setInAppNotificationSound(isEnabled);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.setInAppNotificationSound] phase=exit");
    }

    @Override
    public void getUnreadRepliesCount(@NonNull String callId, RepliesPigeon.Result<Long> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.getUnreadRepliesCount] #" + callId + " phase=enter");
        ThreadManager.runOnBackground(
                new Runnable() {
                    @Override
                    public void run() {
                        final long count = Replies.getUnreadRepliesCount();

                        ThreadManager.runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                                        "[REP.getUnreadRepliesCount] #" + callId + " phase=exit result=" + count);
                                result.success(count);
                            }
                        });
                    }
                }
        );
    }

    @Override
    public void hasChats(@NonNull String callId, RepliesPigeon.Result<Boolean> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.hasChats] #" + callId + " phase=enter");
        ThreadManager.runOnBackground(
                new Runnable() {
                    @Override
                    public void run() {
                        final boolean hasChats = Replies.hasChats();

                        ThreadManager.runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                                        "[REP.hasChats] #" + callId + " phase=exit result=" + hasChats);
                                result.success(hasChats);
                            }
                        });
                    }
                }
        );
    }

    @Override
    public void bindOnNewReplyCallback() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                "[REP.bindOnNewReplyCallback] phase=enter");
        Replies.setOnNewReplyReceivedCallback(new Runnable() {
            @Override
            public void run() {
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        String callId = LuciqFlutterLogger.nextCallId();
                        LuciqFlutterLogger.d(LuciqFlutterDebugTags.REPLIES,
                                "[REP.onNewReply] #" + callId + " phase=fire");
                        flutterApi.onNewReply(callId, new RepliesPigeon.RepliesFlutterApi.Reply<Void>() {
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
