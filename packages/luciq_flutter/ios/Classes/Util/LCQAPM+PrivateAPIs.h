//
//  LCQAPM+PrivateAPIs.h
//  Luciq
//
//  Created by Yousef Hamza on 9/7/20.
//  Copyright © 2020 Moataz. All rights reserved.
//

#import <LuciqSDK/LCQAPM.h>
#import "LCQTimeIntervalUnits.h"

@interface LCQAPM (PrivateAPIs)


/// `endScreenLoadingEnabled` will be only true if  APM, screenLoadingFeature.enabled and autoUITracesUserPreference are true
@property (class, atomic, assign) BOOL endScreenLoadingEnabled;

+ (void)startUITraceCPWithName:(NSString *)name startTimestampMUS:(LCQMicroSecondsTimeInterval)startTimestampMUS;

+ (void)reportScreenLoadingCPWithStartTimestampMUS:(LCQMicroSecondsTimeInterval)startTimestampMUS
                                       durationMUS:(LCQMicroSecondsTimeInterval)durationMUS;

+ (void)endScreenLoadingCPWithEndTimestampMUS:(LCQMicroSecondsTimeInterval)endTimestampMUS;

@end
