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


@end
