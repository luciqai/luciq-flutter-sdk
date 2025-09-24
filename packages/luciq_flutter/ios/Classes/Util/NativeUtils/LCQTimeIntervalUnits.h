//
//  LCQTimeIntervalUnits.h
//  LuciqUtilities
//
//  Created by Yousef Hamza on 6/4/20.
//  Copyright © 2020 Moataz. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef double LCQMicroSecondsTimeInterval NS_SWIFT_NAME(MicroSecondsTimeInterval);
typedef double LCQMilliSecondsTimeInterval NS_SWIFT_NAME(MilliSecondsTimeInterval);
typedef double LCQMinutesTimeInterval NS_SWIFT_NAME(MinutesTimeInterval);

/// Convert from milli timestamp to micro timestamp
/// - Parameter timeInterval: micro timestamp
LCQMicroSecondsTimeInterval lcq_microSecondsIntervalFromTimeEpoch(NSTimeInterval timeInterval);
LCQMicroSecondsTimeInterval lcq_microSecondsIntervalFromTimeInterval(NSTimeInterval timeInterval);
LCQMilliSecondsTimeInterval lcq_milliSecondsIntervalFromTimeInterval(NSTimeInterval timeInterval);
LCQMinutesTimeInterval lcq_minutesIntervalFromTimeInterval(NSTimeInterval timeInterval);

NSTimeInterval lcq_timeIntervalFromMicroSecondsInterval(LCQMicroSecondsTimeInterval timeInterval);
NSTimeInterval lcq_timeIntervalFromMilliSecondsInterval(LCQMilliSecondsTimeInterval timeInterval);
NSTimeInterval lcq_timeIntervalFromMinutesInterval(LCQMinutesTimeInterval timeInterval);
