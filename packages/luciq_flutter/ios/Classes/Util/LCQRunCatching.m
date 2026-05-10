#import "LCQRunCatching.h"

void LCQRunCatching(NSString *method, void (^block)(void)) {
    @try {
        block();
    } @catch (NSException *e) {
        NSLog(@"[Luciq] %@ failed: %@ — %@\n%@",
              method, e.name, e.reason, e.callStackSymbols);
    }
}

id LCQRunCatchingReturn(NSString *method, id fallback, id (^block)(void)) {
    @try {
        return block();
    } @catch (NSException *e) {
        NSLog(@"[Luciq] %@ failed: %@ — %@\n%@",
              method, e.name, e.reason, e.callStackSymbols);
        return fallback;
    }
}
