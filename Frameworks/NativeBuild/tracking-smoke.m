#import <AppKit/AppKit.h>
#import <PSMTabBar/PSMTabBarControl.h>
#import <PSMTabBar/PSMTabBarCell.h>
#import <PSMTabBar/PSMRolloverButton.h>

@interface PSMTabBarControl (TrackingSmokeAccess)
- (NSMutableArray *)cells;
@end

// Simulate a nib created by the old version, which wrote live tracking handles.
@interface LegacyTrackingCell : PSMTabBarCell
@end
@implementation LegacyTrackingCell
- (Class)classForCoder { return [PSMTabBarCell class]; }
- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeInteger:1234567 forKey:@"cellTrackingTag"];
    [coder encodeInteger:7654321 forKey:@"closeButtonTrackingTag"];
}
@end

@interface LegacyTrackingButton : PSMRolloverButton
@end
@implementation LegacyTrackingButton
- (Class)classForCoder { return [PSMRolloverButton class]; }
- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeInteger:1234567 forKey:@"myTrackingRectTag"];
}
@end

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        @try {
            NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 640, 400)
                                                         styleMask:NSWindowStyleMaskTitled
                                                           backing:NSBackingStoreBuffered defer:NO];
            [window setReleasedWhenClosed:NO];
            PSMTabBarControl *bar = [[PSMTabBarControl alloc] initWithFrame:NSMakeRect(0, 360, 640, 24)];
            NSTabView *tabs = [[NSTabView alloc] initWithFrame:NSMakeRect(0, 0, 640, 360)];
            [bar setTabView:tabs];
            [[window contentView] addSubview:tabs];
            [[window contentView] addSubview:bar];
            for (NSUInteger i = 0; i < 3; i++) {
                NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:@(i)];
                [item setLabel:[NSString stringWithFormat:@"Tab %lu", (unsigned long)i]];
                [tabs addTabViewItem:item];
                [item release];
            }
            [bar awakeFromNib];
            [bar setCanCloseOnlyTab:YES];
            [bar setShowAddTabButton:YES];
            for (NSUInteger i = 0; i < 50; i++) {
                [bar setFrameSize:NSMakeSize(640 - (i % 5) * 45, 24)];
                [bar update:NO];
                [bar setDisableTabClose:(i % 2 == 0)];
                [[bar addTabButton] resetCursorRects];
            }
            NSCAssert([[bar cells] count] == 3, @"Unexpected tab count");
            for (PSMTabBarCell *cell in [bar cells]) {
                NSCAssert([cell cellTrackingTag] != 0, @"Missing live cell tracker");
            }
            [bar setDisableTabClose:YES];
            [bar update:NO];
            for (PSMTabBarCell *cell in [bar cells]) {
                NSCAssert([cell closeButtonTrackingTag] == 0, @"Suppressed close button kept tracking");
            }
            LegacyTrackingCell *legacyCell = [[LegacyTrackingCell alloc] initWithControlView:bar];
            NSData *cellData = [NSKeyedArchiver archivedDataWithRootObject:legacyCell];
            PSMTabBarCell *restoredCell = [NSKeyedUnarchiver unarchiveObjectWithData:cellData];
            NSCAssert([restoredCell cellTrackingTag] == 0 && [restoredCell closeButtonTrackingTag] == 0,
                      @"Cell restored stale tracking handles");
            [legacyCell release];
            LegacyTrackingButton *legacyButton = [[LegacyTrackingButton alloc] initWithFrame:NSMakeRect(0, 0, 20, 20)];
            NSData *buttonData = [NSKeyedArchiver archivedDataWithRootObject:legacyButton];
            PSMRolloverButton *restoredButton = [NSKeyedUnarchiver unarchiveObjectWithData:buttonData];
            // Any saved handle would assert when removeTrackingRect is called.
            [restoredButton removeTrackingRect];
            [restoredButton resetCursorRects];
            [restoredButton removeTrackingRect];
            [legacyButton release];
            [bar removeFromSuperview];
            [tabs removeFromSuperview];
            [window close];
            [bar release];
            [tabs release];
            [window release];
            puts("PSM tracking smoke passed: initial layout, 50 resizes/updates, close suppression, legacy nib handles, teardown.");
        }
        @catch (NSException *exception) {
            fprintf(stderr, "PSM tracking smoke failed: %s: %s\n", [[exception name] UTF8String], [[exception reason] UTF8String]);
            return 1;
        }
    }
    return 0;
}
