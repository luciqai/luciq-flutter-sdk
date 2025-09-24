// This header file makes LCQSurvey title property editable to be used in tests.

#import <LuciqSDK/LCQSurveys.h>

@interface LCQSurvey (Test)
@property (nonatomic, strong) NSString *title;
@end
