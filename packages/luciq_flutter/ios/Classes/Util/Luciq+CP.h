
#import <Foundation/Foundation.h>

@interface Luciq (CP)

+ (void)setScreenshotMaskingHandler:(nullable void (^)(UIImage *, void (^)(UIImage *)))maskingHandler;
@property(nonatomic, assign, class) BOOL sendEventsSwizzling;

@end
