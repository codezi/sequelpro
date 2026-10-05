#import <Foundation/Foundation.h>
#import <UniversalDetector/UniversalDetector.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <FeedbackReporter/FRFeedbackReporter.h>
#import <Growl/Growl.h>
#import <OCMock/OCMock.h>
#import <Sparkle/Sparkle.h>

int main(void) {
    @autoreleasepool {
        UniversalDetector *detector = [UniversalDetector detector];
        NSData *utf8 = [@"Dữ liệu tiếng Việt, bảng và câu truy vấn. 日本語の文字列。" dataUsingEncoding:NSUTF8StringEncoding];
        [detector analyzeData:utf8];
        NSCAssert([detector encoding] == NSUTF8StringEncoding, @"UTF-8 detection failed: %@", [detector MIMECharset]);
        [detector reset];
        [detector analyzeData:[@"Plain ASCII query SELECT 1" dataUsingEncoding:NSASCIIStringEncoding]];
        NSCAssert([detector encoding] == NSASCIIStringEncoding || [detector encoding] == NSUTF8StringEncoding, @"ASCII detection failed");
        KeyCombo combo = SRMakeKeyCombo(0, NSEventModifierFlagCommand);
        NSCAssert(combo.code == 0 && combo.flags == NSEventModifierFlagCommand, @"KeyCombo ABI failed");
        NSCAssert([SRRecorderControl class] != Nil && [SRRecorderCell class] != Nil, @"Missing legacy shortcut classes");
        NSCAssert([FRFeedbackReporter sharedReporter] != nil, @"Missing feedback reporter");
        NSCAssert([GrowlApplicationBridge class] != Nil && [SUUpdater class] != Nil, @"Missing legacy notification/updater classes");
        id mock = [OCMockObject niceMockForClass:[NSString class]];
        [[[mock stub] andReturn:@"native"] lowercaseString];
        NSCAssert([[mock lowercaseString] isEqualToString:@"native"], @"OCMock arm64 dispatch failed");
        puts("Native dependency smoke test passed: detector UTF-8/reset, legacy shortcut ABI/classes, reporter, Growl, Sparkle, OCMock dispatch.");
    }
    return 0;
}
