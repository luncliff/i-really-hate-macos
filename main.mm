#import "interface.h"

@implementation WD
- (void)windowWillClose:(NSNotification*)notification {
    if (timer)
        [timer invalidate];
    NSWindow* window = notification.object;
    NSLog(@"window close: %@", window.title);
}
- (NSSize)windowWillResize:(NSWindow*)window toSize:(NSSize)size {
    NSLog(@"window will resize: w %.2f h %.2f", size.width, size.height);
    return size;
}
- (void)scheduleMTKView:(MTKView*)view context:(void*)ptr {
    NSLog(@"view: %@", [view className]);
    if (NSWindow* window = [view window]) {
        NSLog(@"window: %@", [window className]);
    }
    if (CALayer* layer = [view layer]) {
        NSLog(@"layer: %@", [layer className]);
    }
    // start after 1 seconds
    timer =
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(initiateWithTimer:)
                                       userInfo:nil
                                        repeats:NO];
    NSLog(@"window delegate: scheduled");
}
/// @todo consider using `NSDictionary`
- (void)initiateWithTimer:(NSTimer*)_ {
    const UInt16 checkInSec = 10; // check 10 times in 1 second.
    timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / checkInSec)
                                             target:self
                                           selector:@selector(updateWithTimer:)
                                           userInfo:self
                                            repeats:YES];
    NSLog(@"window delegate: initiated");
}
- (void)updateWithTimer:(NSTimer*)_ {
    // NSLog(@"window delegate: updated");
}
@end

// ...
// @interface AD : NSObject <NSApplicationDelegate>
// @end
@implementation AD
- (NSWindow*)makeWindow:(id<NSWindowDelegate>)delegate
                  title:(NSString*)txt
            contentView:(NSView*)view {
    auto window =
        [[NSWindow alloc] initWithContentRect:view.visibleRect
                                    styleMask:NSWindowStyleMaskTitled |
                                              NSWindowStyleMaskClosable |
                                              NSWindowStyleMaskResizable
                                      backing:NSBackingStoreBuffered
                                        defer:YES];
    window.backgroundColor = [NSColor whiteColor];
    window.minSize = NSMakeSize(1280, 720);
    /// @todo use minimum boundary of the `view`
    window.title = txt;
    [window setDelegate:delegate];
    [window setContentView:view];
    [window makeKeyAndOrderFront:self];
    [window setAcceptsMouseMovedEvents:NO];
    return window;
}

/// @todo setup engine instance and reserve resources
/// @see https://stackoverflow.com/questions/56084303/opencv-command-line-app-cant-access-camera-under-macos-mojave
- (void)applicationDidFinishLaunching:(NSNotification*)_ {
    NSLog(@"application did finish launching");
    acquireCameraPermission();
}
- (void)applicationWillTerminate:(NSNotification*)_ {
    NSLog(@"application will terminate");
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)app {
    return YES;
}
@end

int main(int argc, char* argv[]) {
    if (auto ec = init(argc, argv)) {
        NSLog(@"failed to initialize application: %d", ec);
        return ec;
    }
    @autoreleasepool {
        NSApp = [NSApplication sharedApplication];
        auto appd = [[AD alloc] init];
        [NSApp setDelegate:appd];
        {
            auto window = makeWindowForMtkView( //
                appd, @"MtkView", nullptr);
            if (window == nil)
                return __LINE__;
            NSLog(@"created window: %@", window.title);
        }
        {
            auto window = makeWindowForAVCaptureSession( //
                appd, @"AVCaptureSession", [[AVCaptureSession alloc] init]);
            if (window == nil)
                return __LINE__;
            NSLog(@"created window: %@", window.title);
        }
        return [NSApp run], 0;
    }
}
