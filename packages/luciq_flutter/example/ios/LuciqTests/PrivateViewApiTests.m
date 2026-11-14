#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <PrivateViewApi.h>
#import <Flutter/Flutter.h>
#import "FlutterPluginRegistrar+FlutterEngine.h"


@interface MockFlutterPluginRegistrar : NSObject <FlutterPluginRegistrar>
@end

@implementation MockFlutterPluginRegistrar

@end


@interface PrivateViewApiTests : XCTestCase
@property (nonatomic, strong) PrivateViewApi *api;
@property (nonatomic, strong) id mockFlutterApi;
@property (nonatomic, strong) id mockRegistrar;
@property (nonatomic, strong) id mockFlutterViewController;
@property (nonatomic, strong) id mockEngine;
@property (nonatomic, strong) UIWindow *testWindow;

@end

@implementation PrivateViewApiTests

#pragma mark - Setup / Teardown

- (void)setUp {
    [super setUp];

    
    self.mockFlutterApi = OCMClassMock([LuciqPrivateViewFlutterApi class]);


    MockFlutterPluginRegistrar *mockRegistrar = [[MockFlutterPluginRegistrar alloc] init];

    self.mockRegistrar = OCMPartialMock(mockRegistrar);

    self.mockEngine = OCMClassMock([FlutterEngine class]);
        OCMStub([self.mockRegistrar flutterEngine]).andReturn(self.mockEngine);

        self.mockFlutterViewController = OCMClassMock([UIViewController class]);

    OCMStub([self.mockEngine viewController]).andReturn(_mockFlutterViewController);
    
    self.api = OCMPartialMock([[PrivateViewApi alloc] initWithFlutterApi:self.mockFlutterApi registrar: self.mockRegistrar]);
}

- (void)tearDown {
    [self.mockFlutterApi stopMocking];
    [self.mockRegistrar stopMocking];
    [self.mockFlutterViewController stopMocking];
    [self.mockEngine stopMocking];
    PrivateViewApi.masksHostScreenshot = NO;

    self.api = nil;
    
    [super tearDown];
}

#pragma mark - Tests

- (void)testMask_Success {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Mask method success"];
    
    CGSize imageSize = CGSizeMake(100, 100); // 100x100 pixels

       // Step 2: Create the image using UIGraphicsImageRenderer
       UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:imageSize];

       UIImage *screenshot = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
           // Draw a red rectangle as an example
           [[UIColor redColor] setFill];
           CGRect rect = CGRectMake(0, 0, imageSize.width, imageSize.height);
           UIRectFill(rect);
       }];
    
    NSArray<NSNumber *> *rectangles = @[@10, @20, @30, @40];
    UIView *mockView = [[UIView alloc] initWithFrame:CGRectMake(10, 20, 30, 40)];
    
    OCMStub([self.mockFlutterApi getPrivateViewsCallId:OCMOCK_ANY completion:([OCMArg invokeBlockWithArgs:rectangles, [NSNull null], nil])]);
    
        
  
    OCMStub([self.mockFlutterViewController view]).andReturn(mockView);


    [self.api mask:screenshot completion:^(UIImage *result) {
        XCTAssertNotNil(result, @"Masked image should be returned.");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}


- (void)testGetFlutterViewOrigin_ValidView {
    UIView *mockView = [[UIView alloc] initWithFrame:CGRectMake(10, 20, 100, 100)];
   
    OCMStub([self.mockFlutterViewController view]).andReturn(mockView);
    
    UIWindow*  testWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [testWindow addSubview:mockView];

    CGPoint origin = [self.api getFlutterViewOrigin];
    
    XCTAssertEqual(origin.x, 10);
    XCTAssertEqual(origin.y, 20);
}

- (void)testGetFlutterViewOrigin_NilView {
    
    OCMStub([self.mockFlutterViewController view]).andReturn(nil);
//
    CGPoint origin = [self.api getFlutterViewOrigin];
    
    XCTAssertEqual(origin.x, 0);
    XCTAssertEqual(origin.y, 0);
}

- (void)testDrawMaskedImage {
    CGSize size = CGSizeMake(100, 100);
    UIGraphicsBeginImageContext(size);
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSArray<NSValue *> *privateViews = @[
        [NSValue valueWithCGRect:CGRectMake(10, 10, 20, 20)],
        [NSValue valueWithCGRect:CGRectMake(30, 30, 10, 10)]
    ];
    
    UIImage *result = [self.api drawMaskedImage:screenshot withPrivateViews:privateViews];
    
    XCTAssertNotNil(result);
    XCTAssertEqual(result.size.width, 100);
    XCTAssertEqual(result.size.height, 100);
}

- (void)testConvertToRectangles_ValidInput {
    NSArray<NSNumber *> *rectangles = @[@10, @20, @30, @40];
    UIView *mockView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 100, 100)];
    OCMStub([self.mockFlutterViewController view]).andReturn(mockView);

    
    NSArray<NSValue *> *converted = [self.api convertToRectangles:rectangles];
    
    XCTAssertEqual(converted.count, 1);
    CGRect rect = [converted[0] CGRectValue];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(10, 20, 21, 21)));
}

- (void)testConcurrentMaskCalls {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handle concurrent calls"];
    
    CGSize imageSize = CGSizeMake(100, 100); // 100x100 pixels

       // Step 2: Create the image using UIGraphicsImageRenderer
       UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:imageSize];

       UIImage *screenshot = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
           // Draw a red rectangle as an example
           [[UIColor redColor] setFill];
           CGRect rect = CGRectMake(0, 0, imageSize.width, imageSize.height);
           UIRectFill(rect);
       }];
    
    NSArray<NSNumber *> *rectangles = @[@10, @20, @30, @40];
    
    
    OCMStub([self.mockFlutterApi getPrivateViewsCallId:OCMOCK_ANY completion:([OCMArg invokeBlockWithArgs:rectangles, [NSNull null], nil])]);
    
    
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 5; i++) {
        dispatch_group_enter(group);
        
        [self.api mask:screenshot completion:^(UIImage *result) {
            XCTAssertNotNil(result, @"Each call should return a valid image.");
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma mark - Flutter view visibility

- (UIView *)flutterViewInWindowWithFrame:(CGRect)frame {
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 400, 800)];
    UIView *flutterView = [[UIView alloc] initWithFrame:frame];
    [window addSubview:flutterView];
    window.hidden = NO;
    self.testWindow = window;
    OCMStub([self.mockFlutterViewController isViewLoaded]).andReturn(YES);
    OCMStub([self.mockFlutterViewController view]).andReturn(flutterView);
    return flutterView;
}

- (void)testIsFlutterViewVisible_whenOnScreen_returnsYes {
    [self flutterViewInWindowWithFrame:CGRectMake(0, 0, 400, 700)];

    XCTAssertTrue([self.api isFlutterViewVisible]);
}

- (void)testIsFlutterViewVisible_whenNotInWindow_returnsNo {
    // A hidden tab or a screen under a pushed one: UIKit removes its view from the window.
    OCMStub([self.mockFlutterViewController isViewLoaded]).andReturn(YES);
    OCMStub([self.mockFlutterViewController view]).andReturn([[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 700)]);

    XCTAssertFalse([self.api isFlutterViewVisible]);
}

- (void)testIsFlutterViewVisible_whenViewNotLoaded_returnsNo {
    OCMStub([self.mockFlutterViewController isViewLoaded]).andReturn(NO);

    XCTAssertFalse([self.api isFlutterViewVisible]);
}

- (void)testIsFlutterViewVisible_whenAnAncestorIsHidden_returnsNo {
    UIView *flutterView = [self flutterViewInWindowWithFrame:CGRectMake(0, 0, 400, 700)];
    UIView *container = [[UIView alloc] initWithFrame:self.testWindow.bounds];
    [self.testWindow addSubview:container];
    [container addSubview:flutterView];
    container.hidden = YES;

    XCTAssertFalse([self.api isFlutterViewVisible]);
}

- (void)testIsFlutterViewVisible_whenTransparent_returnsNo {
    UIView *flutterView = [self flutterViewInWindowWithFrame:CGRectMake(0, 0, 400, 700)];
    flutterView.alpha = 0;

    XCTAssertFalse([self.api isFlutterViewVisible]);
}

- (void)testIsFlutterViewVisible_whenOutsideTheWindow_returnsNo {
    [self flutterViewInWindowWithFrame:CGRectMake(400, 0, 400, 700)];

    XCTAssertFalse([self.api isFlutterViewVisible]);
}

- (void)testIsFlutterViewVisible_whenNoViewController_returnsNo {
    id engine = OCMClassMock([FlutterEngine class]);
    id registrar = OCMPartialMock([[MockFlutterPluginRegistrar alloc] init]);
    OCMStub([registrar flutterEngine]).andReturn(engine);
    PrivateViewApi *api = [[PrivateViewApi alloc] initWithFlutterApi:self.mockFlutterApi registrar:registrar];

    XCTAssertFalse([api isFlutterViewVisible]);
}

- (void)testMask_whenFlutterViewIsNotVisible_returnsTheScreenshotWithoutAskingDart {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completion"];
    UIImage *screenshot = [[UIImage alloc] init];
    OCMStub([self.mockFlutterViewController isViewLoaded]).andReturn(NO);
    OCMReject([self.mockFlutterApi getPrivateViewsCallId:OCMOCK_ANY completion:OCMOCK_ANY]);

    [self.api mask:screenshot completion:^(UIImage *result) {
        XCTAssertEqual(result, screenshot);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testMask_whenFlutterViewIsVisible_asksDartForPrivateViews {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completion"];
    [self flutterViewInWindowWithFrame:CGRectMake(0, 0, 400, 700)];
    OCMStub([self.mockFlutterApi getPrivateViewsCallId:OCMOCK_ANY
                                            completion:([OCMArg invokeBlockWithArgs:@[@10, @20, @30, @40], [NSNull null], nil])]);

    [self.api mask:[[UIImage alloc] init] completion:^(UIImage *result) {
        XCTAssertNotNil(result);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
    OCMVerify([self.mockFlutterApi getPrivateViewsCallId:OCMOCK_ANY completion:OCMOCK_ANY]);
}

#pragma mark - Hybrid apps

- (UIImage *)solidImageOfSize:(CGSize)size color:(UIColor *)color {
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1;
    return [[[UIGraphicsImageRenderer alloc] initWithSize:size format:format]
        imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [color setFill];
            [context fillRect:CGRectMake(0, 0, size.width, size.height)];
        }];
}

- (UIColor *)colorOfImage:(UIImage *)image atPoint:(CGPoint)point {
    CGImageRef cgImage = image.CGImage;
    CGFloat scale = image.scale;
    unsigned char pixel[4] = {0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, -point.x * scale, -(CGImageGetHeight(cgImage) - point.y * scale - 1));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage)), cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return [UIColor colorWithRed:pixel[0] / 255.0 green:pixel[1] / 255.0 blue:pixel[2] / 255.0 alpha:pixel[3] / 255.0];
}

- (void)testMask_whenAttachedToNativeApp_drawsTheDartMasksOnTheNativelyMaskedCapture {
    PrivateViewApi.masksHostScreenshot = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"completion"];
    [self flutterViewInWindowWithFrame:CGRectMake(0, 0, 400, 700)];
    // Stands in for the SDK's natively masked capture: a plain capture of the window would not be red.
    UIImage *nativelyMasked = [self solidImageOfSize:CGSizeMake(400, 700) color:UIColor.redColor];
    OCMStub([(PrivateViewApi *)self.api captureNativelyMaskedScreenshot]).andReturn(nativelyMasked);
    OCMStub([self.mockFlutterApi getPrivateViewsCallId:OCMOCK_ANY
                                            completion:([OCMArg invokeBlockWithArgs:@[@10, @20, @30, @40], [NSNull null], nil])]);

    __block UIImage *masked;
    [self.api mask:[[UIImage alloc] init] completion:^(UIImage *result) {
        masked = result;
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertEqualObjects([self colorOfImage:masked atPoint:CGPointMake(15, 25)], [UIColor colorWithRed:0 green:0 blue:0 alpha:1]);
    XCTAssertEqualObjects([self colorOfImage:masked atPoint:CGPointMake(200, 300)], [UIColor colorWithRed:1 green:0 blue:0 alpha:1]);
}

- (void)testMask_whenAttachedToNativeAppWithoutTheSDKCapturer_usesTheGivenScreenshot {
    PrivateViewApi.masksHostScreenshot = YES;
    XCTestExpectation *expectation = [self expectationWithDescription:@"completion"];
    [self flutterViewInWindowWithFrame:CGRectMake(0, 0, 400, 700)];
    UIImage *screenshot = [self solidImageOfSize:CGSizeMake(400, 700) color:UIColor.redColor];
    OCMStub([(PrivateViewApi *)self.api captureNativelyMaskedScreenshot]).andReturn(nil);
    FlutterError *error = [FlutterError errorWithCode:@"error" message:nil details:nil];
    OCMStub([self.mockFlutterApi getPrivateViewsCallId:OCMOCK_ANY
                                            completion:([OCMArg invokeBlockWithArgs:[NSNull null], error, nil])]);

    [self.api mask:screenshot completion:^(UIImage *result) {
        XCTAssertEqual(result, screenshot);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
