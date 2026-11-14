#import "PrivateViewApi.h"
#import "FlutterPluginRegistrar+FlutterEngine.h"
#import "LuciqFlutterLogger.h"
#import "LuciqFlutterDebugTags.h"
#import <objc/message.h>

extern PrivateViewApi* InitPrivateViewApi(
    id<FlutterBinaryMessenger> messenger,
    NSObject<FlutterPluginRegistrar> *flutterEngineRegistrar
) {
    LuciqPrivateViewFlutterApi *flutterApi = [[LuciqPrivateViewFlutterApi alloc] initWithBinaryMessenger:messenger];
    return [[PrivateViewApi alloc] initWithFlutterApi:flutterApi registrar:flutterEngineRegistrar];
}

@implementation PrivateViewApi

static BOOL _masksHostScreenshot = NO;

+ (BOOL)masksHostScreenshot {
    return _masksHostScreenshot;
}

+ (void)setMasksHostScreenshot:(BOOL)masksHostScreenshot {
    _masksHostScreenshot = masksHostScreenshot;
}

// Initializer with proper memory management
- (instancetype)initWithFlutterApi:(LuciqPrivateViewFlutterApi *)api
                         registrar:( NSObject<FlutterPluginRegistrar> *) registrar {
    if ((self = [super init])) {
        _flutterApi = api;
        _flutterEngineRegistrar = registrar;
    }
    return self;
}

static long long currentTimeMillis;


- (void)mask:(UIImage *)screenshot
  completion:(void (^)(UIImage *))completion {
    NSString *callId = [LuciqFlutterLogger nextCallId];
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags privateView]
                   format:@"[PRIV.mask] #%@ phase=enter screenshotWidth=%.0f screenshotHeight=%.0f",
        callId, screenshot.size.width, screenshot.size.height];

    // A Flutter view that is not on screen (a hidden tab, or under a pushed native screen) still
    // reports the private views of its last route. Masking them would black out native content.
    if (![self isFlutterViewVisible]) {
        [LuciqFlutterLogger d:[LuciqFlutterDebugTags privateView]
                       format:@"[PRIV.mask] #%@ phase=exit skipped=flutterViewNotVisible", callId];
        completion(screenshot);
        return;
    }

    __weak typeof(self) weakSelf = self;
    // Wait for the Cupertino animation to complete
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags privateView]
                   format:@"[PRIV.capture] #%@ phase=fire", callId];
    [self.flutterApi getPrivateViewsCallId:callId completion:^(NSArray<NSNumber *> *rectangles, FlutterError *error) {
        // In a hybrid app the capture must keep the native masks (native private views and
        // auto-masked native views): the SDK takes it. The screenshot the SDK passed in has them
        // too, but may predate the Flutter view's first frame.
        UIImage *capturedScreenshot = PrivateViewApi.masksHostScreenshot
            ? ([weakSelf captureNativelyMaskedScreenshot] ?: screenshot)
            : [self captureScreenshot];
        // The Flutter view may have left the screen during the delay (a tab switch or a push).
        if (![weakSelf isFlutterViewVisible]) {
            [LuciqFlutterLogger d:[LuciqFlutterDebugTags privateView]
                           format:@"[PRIV.mask] #%@ phase=exit skipped=flutterViewNotVisible", callId];
            completion(capturedScreenshot);
            return;
        }
            [weakSelf handlePrivateViewsResult:rectangles
                                         error:error
                                    screenshot:capturedScreenshot
                                      callId:callId
                                    completion:completion];
      }];
    });
}

#pragma mark - Private Methods

// A screenshot taken by the SDK's own capturer with its native masking rules applied. The capturer
// is not public, so it is reached by name; returns nil when the SDK doesn't have it.
- (nullable UIImage *)captureNativelyMaskedScreenshot {
    Class capturerClass = NSClassFromString(@"InstabugScreenCapturer");
    SEL instanceSelector = NSSelectorFromString(@"getInstance");
    SEL captureSelector = NSSelectorFromString(@"takeScreenshotWithAnnotator:shouldUseRenderInContext:lastTouchedPoints:shouldApplyMaskingRules:");
    if (![capturerClass respondsToSelector:instanceSelector]) {
        return nil;
    }
    id capturer = ((id (*)(id, SEL))objc_msgSend)(capturerClass, instanceSelector);
    if (![capturer respondsToSelector:captureSelector]) {
        return nil;
    }
    // The SDK captures without waiting for screen updates, so a Flutter view that just appeared
    // would still be blank. Drawing its window once after screen updates commits the pending frame.
    UIWindow *window = self.flutterEngineRegistrar.flutterEngine.viewController.view.window;
    if (window != nil) {
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:window.bounds.size];
        [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        }];
    }
    return ((UIImage *(*)(id, SEL, id, BOOL, id, BOOL))objc_msgSend)(capturer, captureSelector, nil, NO, nil, YES);
}

// Method to capture a screenshot of the app's main window
- (UIImage *)captureScreenshot {
    CGSize imageSize = UIScreen.mainScreen.bounds.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, UIScreen.mainScreen.scale);

    // Iterate over all windows, including the keyboard window
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
    }

    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenshot;
}

// Handle the result of fetching private views
- (void)handlePrivateViewsResult:(NSArray<NSNumber *> *)rectangles
                           error:(FlutterError *)error
                      screenshot:(UIImage *)screenshot
                          callId:(NSString *)callId
                      completion:(void (^)(UIImage *))completion {
    if (error) {
        [self logError:error callId:callId];
        completion(screenshot);
        return;
    }

    NSArray<NSValue *> *privateViews = [self convertToRectangles:rectangles];
    UIImage *maskedScreenshot = [self drawMaskedImage:screenshot withPrivateViews:privateViews];
    static long long currentTimeMillis2;
    currentTimeMillis2 = (long long)([[NSDate date] timeIntervalSince1970] * 1000);

    long long timeDifference = currentTimeMillis2 - currentTimeMillis;

    completion(maskedScreenshot);
    [LuciqFlutterLogger d:[LuciqFlutterDebugTags privateView]
                   format:@"[PRIV.mask] #%@ phase=exit durationMs=%lld rectangleCount=%lu",
        callId, timeDifference, (unsigned long)privateViews.count];


}

// Convert the raw rectangles array into CGRect values
- (NSArray<NSValue *> *)convertToRectangles:(NSArray<NSNumber *> *)rectangles {
    
    NSMutableArray<NSValue *> *privateViews = [NSMutableArray arrayWithCapacity:rectangles.count / 4];
    CGPoint flutterOrigin = [self getFlutterViewOrigin];

    for (NSUInteger i = 0; i < rectangles.count; i += 4) {
        CGFloat left = rectangles[i].doubleValue;
        CGFloat top = rectangles[i + 1].doubleValue;
        CGFloat right = rectangles[i + 2].doubleValue;
        CGFloat bottom = rectangles[i + 3].doubleValue;

        CGRect rect = CGRectMake(flutterOrigin.x + left,
                                 flutterOrigin.y + top,
                                 right - left + 1,
                                 bottom - top + 1);
        [privateViews addObject:[NSValue valueWithCGRect:rect]];
    }
    return privateViews;
}

// Draw the masked image by filling private views with black rectangles
- (UIImage *)drawMaskedImage:(UIImage *)screenshot withPrivateViews:(NSArray<NSValue *> *)privateViews {
    UIGraphicsBeginImageContextWithOptions(screenshot.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    @try {
        [screenshot drawAtPoint:CGPointZero];
        CGContextSetFillColorWithColor(context, UIColor.blackColor.CGColor);

        for (NSValue *value in privateViews) {
            CGContextFillRect(context, value.CGRectValue);
        }

        return UIGraphicsGetImageFromCurrentImageContext();
    } @finally {
        UIGraphicsEndImageContext();
    }
}

// Whether the engine's Flutter view is in a window, not hidden and at least partly on screen.
// UIKit removes the views of unselected tabs and of screens under a pushed one from the window.
- (BOOL)isFlutterViewVisible {
    UIViewController *flutterVC = self.flutterEngineRegistrar.flutterEngine.viewController;
    if (flutterVC == nil || !flutterVC.isViewLoaded) {
        return NO;
    }
    UIView *flutterView = flutterVC.view;
    UIWindow *window = flutterView.window;
    if (window == nil) {
        return NO;
    }
    for (UIView *view = flutterView; view != nil; view = view.superview) {
        if (view.hidden || view.alpha <= 0.01) {
            return NO;
        }
    }
    CGRect frameInWindow = [flutterView convertRect:flutterView.bounds toView:window];
    return CGRectIntersectsRect(frameInWindow, window.bounds);
}

// Retrieve the origin point of the Flutter view
- (CGPoint)getFlutterViewOrigin {
    FlutterViewController *flutterVC = (FlutterViewController *)self.flutterEngineRegistrar.flutterEngine.viewController;

    UIView *flutterView = flutterVC.view;
    if(!flutterView)
        return  CGPointZero;
    UIWindow *window = flutterView.window;
    CGRect globalFrame = [flutterView convertRect:flutterView.bounds toView:window];

    return globalFrame.origin ;
}


// Log error details
- (void)logError:(FlutterError *)error callId:(NSString *)callId {
    [LuciqFlutterLogger e:[LuciqFlutterDebugTags privateView]
                   format:@"[PRIV.mask] #%@ phase=error errorType=PigeonError errorCode=%@",
        callId, error.code];
}


@end
