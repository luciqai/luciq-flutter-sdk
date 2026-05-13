#import <XCTest/XCTest.h>
#import <luciq_flutter/LuciqFlutterPlugin.h>
#import <luciq_flutter/SessionReplayApi.h>
#import "OCMock/OCMock.h"
#import "SessionReplayApi.h"
#import "LuciqSDK/LCQSessionReplay.h"

@interface SessionReplayApiTests : XCTestCase

@property (nonatomic, strong) id mSessionReplay;
@property (nonatomic, strong) SessionReplayApi *api;

@end

@implementation SessionReplayApiTests

- (void)setUp {
    self.mSessionReplay = OCMClassMock([LCQSessionReplay class]);
    self.api = [[SessionReplayApi alloc] init];
}


- (void)testSetEnabled {
    NSNumber *isEnabled = @1;
    FlutterError *error;

    [self.api setEnabledIsEnabled:isEnabled error:&error];

    OCMVerify([self.mSessionReplay setEnabled:YES]);
}

- (void)testSetLuciqLogsEnabled {
    NSNumber *isEnabled = @1;
    FlutterError *error;

    [self.api setLuciqLogsEnabledIsEnabled:isEnabled error:&error];

    OCMVerify([self.mSessionReplay setLCQLogsEnabled:YES]);
}

- (void)testSetNetworkLogsEnabled {
    NSNumber *isEnabled = @1;
    FlutterError *error;

    [self.api setNetworkLogsEnabledIsEnabled:isEnabled error:&error];

    OCMVerify([self.mSessionReplay setNetworkLogsEnabled:YES]);
}

- (void)testSetUserStepsEnabled {
    NSNumber *isEnabled = @1;
    FlutterError *error;

    [self.api setUserStepsEnabledIsEnabled:isEnabled error:&error];

    OCMVerify([self.mSessionReplay setUserStepsEnabled:YES]);
}

- (void)testGetSessionReplayLink {
    NSString *link = @"link";
    id result = ^(NSString * result, FlutterError * error) {
        XCTAssertEqualObjects(result, link);
    };

    OCMStub([self.mSessionReplay sessionReplayLink]).andReturn(link);
    [self.api getSessionReplayLinkWithCompletion:result];
    OCMVerify([self.mSessionReplay sessionReplayLink]);

}

- (void)testSetScreenshotCapturingModeNavigation {
    FlutterError *error;

    [self.api setScreenshotCapturingModeMode:@"ScreenshotCapturingMode.navigation" error:&error];

    OCMVerify([self.mSessionReplay setScreenshotCapturingMode:LCQScreenshotCapturingModeNavigation]);
}

- (void)testSetScreenshotCapturingModeInteraction {
    FlutterError *error;

    [self.api setScreenshotCapturingModeMode:@"ScreenshotCapturingMode.interaction" error:&error];

    OCMVerify([self.mSessionReplay setScreenshotCapturingMode:LCQScreenshotCapturingModeInteraction]);
}

- (void)testSetScreenshotCapturingModeFrequency {
    FlutterError *error;

    [self.api setScreenshotCapturingModeMode:@"ScreenshotCapturingMode.frequency" error:&error];

    OCMVerify([self.mSessionReplay setScreenshotCapturingMode:LCQScreenshotCapturingModeFrequency]);
}

- (void)testSetScreenshotCaptureInterval {
    NSNumber *intervalMs = @1000;
    FlutterError *error;

    [self.api setScreenshotCaptureIntervalIntervalMs:intervalMs error:&error];

    OCMVerify([self.mSessionReplay setScreenshotCaptureInterval:intervalMs.integerValue]);
}

- (void)testSetScreenshotQualityModeNormal {
    FlutterError *error;

    [self.api setScreenshotQualityModeMode:@"ScreenshotQualityMode.normal" error:&error];

    OCMVerify([self.mSessionReplay setScreenshotQualityMode:LCQScreenshotQualityModeNormal]);
}

- (void)testSetScreenshotQualityModeHigh {
    FlutterError *error;

    [self.api setScreenshotQualityModeMode:@"ScreenshotQualityMode.high" error:&error];

    OCMVerify([self.mSessionReplay setScreenshotQualityMode:LCQScreenshotQualityModeHigh]);
}

- (void)testSetScreenshotQualityModeGreyScale {
    FlutterError *error;

    [self.api setScreenshotQualityModeMode:@"ScreenshotQualityMode.greyScale" error:&error];

    OCMVerify([self.mSessionReplay setScreenshotQualityMode:LCQScreenshotQualityModeGreyScale]);
}

- (void)testEvaluateSyncResolvesPendingCompletionsInFifoOrder {
    // Two pending completions are queued (mirrors two concurrent invocations of the
    // sync listener). Each evaluateSync call must resolve exactly one pending entry
    // in FIFO order — not overwrite a single shared slot.
    XCTestExpectation *firstCalled = [self expectationWithDescription:@"first completion called with NO"];
    XCTestExpectation *secondCalled = [self expectationWithDescription:@"second completion called with YES"];

    self.api.pendingSessionEvaluationCompletions = [NSMutableArray array];
    [self.api.pendingSessionEvaluationCompletions addObject:[^(BOOL value) {
        XCTAssertFalse(value);
        [firstCalled fulfill];
    } copy]];
    [self.api.pendingSessionEvaluationCompletions addObject:[^(BOOL value) {
        XCTAssertTrue(value);
        [secondCalled fulfill];
    } copy]];

    FlutterError *error;
    [self.api evaluateSyncResult:@NO error:&error];
    [self.api evaluateSyncResult:@YES error:&error];

    [self waitForExpectations:@[firstCalled, secondCalled] timeout:1.0 enforceOrder:YES];
    XCTAssertEqual(self.api.pendingSessionEvaluationCompletions.count, 0);
}

- (void)testEvaluateSyncBeforeBindIsNoOp {
    // Calling evaluateSync with no pending completion must not crash.
    self.api.pendingSessionEvaluationCompletions = [NSMutableArray array];
    FlutterError *error;
    [self.api evaluateSyncResult:@YES error:&error];
}

@end
