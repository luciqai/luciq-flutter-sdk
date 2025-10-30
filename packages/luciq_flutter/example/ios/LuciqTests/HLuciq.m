#import "HLuciq.h"
#import <objc/runtime.h>

@implementation HLuciq

static BOOL _setLocaleCalled = NO;
static LCQLocale _lastLocaleCalled = 0;
static BOOL _swizzlingEnabled = NO;
static Method _originalMethod = NULL;
static Method _swizzledMethod = NULL;

+ (BOOL)setLocaleCalled {
    return _setLocaleCalled;
}

+ (void)setSetLocaleCalled:(BOOL)setLocaleCalled {
    _setLocaleCalled = setLocaleCalled;
}

+ (LCQLocale)lastLocaleCalled {
    return _lastLocaleCalled;
}

+ (void)setLastLocaleCalled:(LCQLocale)lastLocaleCalled {
    _lastLocaleCalled = lastLocaleCalled;
}

+ (void)resetTracking {
    _setLocaleCalled = NO;
    _lastLocaleCalled = 0;
}

+ (void)enableSwizzling {
    if (_swizzlingEnabled) {
        return; // Already enabled
    }
    
    _originalMethod = class_getClassMethod([Luciq class], @selector(setLocale:));
    _swizzledMethod = class_getClassMethod([HLuciq class], @selector(setLocale:));
    
    if (_originalMethod && _swizzledMethod) {
        method_exchangeImplementations(_originalMethod, _swizzledMethod);
        _swizzlingEnabled = YES;
    }
}

+ (void)disableSwizzling {
    if (!_swizzlingEnabled) {
        return; // Already disabled
    }
    
    if (_originalMethod && _swizzledMethod) {
        method_exchangeImplementations(_originalMethod, _swizzledMethod);
        _swizzlingEnabled = NO;
        _originalMethod = NULL;
        _swizzledMethod = NULL;
    }
}

+ (void)setLocale:(LCQLocale)locale {
    _setLocaleCalled = YES;
    _lastLocaleCalled = locale;
    
    // When swizzled, this is actually the original Luciq implementation
    // So we call it to maintain the actual functionality
    [super setLocale:locale];
}

@end
