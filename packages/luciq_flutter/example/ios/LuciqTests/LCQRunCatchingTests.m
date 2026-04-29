#import <XCTest/XCTest.h>
#import "LCQRunCatching.h"

/// Tests for the iOS-side defensive @try/@catch helper introduced in
/// MOB-22385. Mirrors the Dart `runCatching` and Java `RunCatching` tests.
@interface LCQRunCatchingTests : XCTestCase
@end

@implementation LCQRunCatchingTests

- (void)testRunCatchingRunsBlockOnSuccess {
    __block BOOL ran = NO;

    LCQRunCatching(@"Test.method", ^{
        ran = YES;
    });

    XCTAssertTrue(ran);
}

- (void)testRunCatchingSwallowsNSException {
    XCTAssertNoThrow(LCQRunCatching(@"Test.method", ^{
        @throw [NSException exceptionWithName:@"TestException"
                                       reason:@"boom"
                                     userInfo:nil];
    }));
}

- (void)testRunCatchingSwallowsGenericNSException {
    XCTAssertNoThrow(LCQRunCatching(@"Test.method", ^{
        // Forces a runtime selector failure (NSInvalidArgumentException).
        NSObject *o = [[NSObject alloc] init];
        [o performSelector:@selector(thisSelectorDoesNotExist)];
    }));
}

- (void)testRunCatchingReturnReturnsResultOnSuccess {
    NSString *result = LCQRunCatchingReturn(@"Test.method", @"fallback", ^id{
        return @"actual";
    });

    XCTAssertEqualObjects(result, @"actual");
}

- (void)testRunCatchingReturnReturnsFallbackOnException {
    NSNumber *result = LCQRunCatchingReturn(@"Test.method", @(0), ^id{
        @throw [NSException exceptionWithName:@"TestException"
                                       reason:@"boom"
                                     userInfo:nil];
    });

    XCTAssertEqualObjects(result, @(0));
}

- (void)testRunCatchingReturnAcceptsNilFallback {
    id result = LCQRunCatchingReturn(@"Test.method", nil, ^id{
        @throw [NSException exceptionWithName:@"TestException"
                                       reason:@"boom"
                                     userInfo:nil];
    });

    XCTAssertNil(result);
}

@end
