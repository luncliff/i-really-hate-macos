#import "interface.h"

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
- (void)applicationDidFinishLaunching:(NSNotification*)n {
    NSLog(@"application did finish launching");
}
- (void)applicationWillTerminate:(NSNotification*)n {
    NSLog(@"application will terminate");
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)app {
    return YES;
}
@end

uint32_t window1(AD* delegate);
uint32_t window2(AD* delegate);

int init(int argc, char* argv[]);
int main(int argc, char* argv[]) {
    if (auto ec = init(argc, argv)) {
        NSLog(@"failed to initialize application: %d", ec);
        return ec;
    }
    @autoreleasepool {
        NSApp = [NSApplication sharedApplication];
        auto delegate = [[AD alloc] init];
        [NSApp setDelegate:delegate];
        {
            auto window = makeWindowForOpenGL(delegate, @"OpenGL");
            if (window == nil)
                return __LINE__;
            NSLog(@"created window: %@", window.title);
        }
        {
            if (auto ec = window2(delegate))
                return ec;
        }
        return [NSApp run], 0;
    }
}

uint32_t window1(AD* delegate) {
    auto window = makeWindowForMtkView( //
        delegate, @"MtkView", nullptr);
    if (window == nil)
        return __LINE__;
    NSLog(@"created window: %@", window.title);
    return 0;
}

uint32_t window2(AD* delegate) {
    auto window = makeWindowForAVCaptureSession( //
        delegate, @"AVCaptureSession", [[AVCaptureSession alloc] init]);
    if (window == nil)
        return __LINE__;
    NSLog(@"created window: %@", window.title);
    return 0;
}
