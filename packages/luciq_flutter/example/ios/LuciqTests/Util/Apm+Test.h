// This header file defines Luciq methods that are called using selectors for test verification.

#import <LuciqSDK/LCQAPM.h>
#import <LuciqSDK/LuciqSDK.h>

@interface LCQAPM (Test)
+ (void)startUITraceCPWithName:(NSString *)name startTimestampMUS:(NSTimeInterval)startTimestampMUS;
+ (void)reportScreenLoadingCPWithStartTimestampMUS:(NSTimeInterval)startTimestampMUS
                                       durationMUS:(NSTimeInterval)durationMUS;
+ (void)endScreenLoadingCPWithEndTimestampMUS:(NSTimeInterval)endTimestampMUS;
@end
