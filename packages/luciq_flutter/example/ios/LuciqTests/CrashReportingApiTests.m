#import <XCTest/XCTest.h>
#import "OCMock/OCMock.h"
#import "CrashReportingApi.h"
#import "LuciqSDK/LCQCrashReporting.h"
#import "LuciqSDK/LuciqSDK.h"
#import "Util/Luciq+Test.h"
#import "Util/LCQCrashReporting+CP.h"

@interface CrashReportingApiTests : XCTestCase

@property(nonatomic, strong) id mCrashReporting;
@property(nonatomic, strong) id mLuciq;
@property(nonatomic, strong) CrashReportingApi *api;

@end

@implementation CrashReportingApiTests

- (void)setUp {
    self.mLuciq = OCMClassMock([Luciq class]);
    self.mCrashReporting = OCMClassMock([LCQCrashReporting class]);
    self.api = [[CrashReportingApi alloc] init];
}

- (void)testSetEnabled {
    NSNumber *isEnabled = @1;
    FlutterError *error;
    
    [self.api setEnabledIsEnabled:isEnabled error:&error];
    
    OCMVerify([self.mCrashReporting setEnabled:YES]);
}

- (void)testSend {
    NSString *jsonCrash = @"{}";
    NSNumber *isHandled = @0;
    FlutterError *error;
    
    [self.api sendJsonCrash:jsonCrash isHandled:isHandled error:&error];
    
    OCMVerify([self.mCrashReporting cp_reportFatalCrashWithStackTrace:@{}]);
}


- (void)testSendNonFatalErrorJsonCrash {
    NSString *jsonCrash = @"{}";
    NSString *fingerPrint = @"fingerprint";
    NSDictionary *userAttributes = @{@"key": @"value",};
    NSString *lcqNonFatalLevel = @"NonFatalExceptionLevel.error";
    
    FlutterError *error;
    
    [self.api sendNonFatalErrorJsonCrash:jsonCrash
                          userAttributes:userAttributes
                             fingerprint:fingerPrint
                  nonFatalExceptionLevel:lcqNonFatalLevel
                                   error:&error];
    
    OCMVerify([self.mCrashReporting cp_reportNonFatalCrashWithStackTrace:@{}
                level:LCQNonFatalLevelError
                groupingString:fingerPrint
                userAttributes:userAttributes
              ]);
}

@end
