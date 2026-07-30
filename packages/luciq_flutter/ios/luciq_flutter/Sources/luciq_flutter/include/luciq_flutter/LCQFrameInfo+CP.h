/*
 File:       Luciq/LCQFrameInfo.h
 
 Contains:   API for using Luciq's SDK. 
 Version:    14.3.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IBGFrame;

NS_SWIFT_NAME(FrameInfo)
/// Information about a single frame in screen rendering
@interface LCQFrameInfo : NSObject

/// The timestamp when the frame started rendering in microseconds
@property (nonatomic, assign) double startTimestampInMicroseconds;

/// The duration of the frame rendering in microseconds
@property (nonatomic, assign) double durationInMicroseconds;

/// Converts this frame info to a Frame object
- (IBGFrame *)toFrame;

@end

NS_ASSUME_NONNULL_END
