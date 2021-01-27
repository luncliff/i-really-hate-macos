#import "interface.h"

uint32_t init(int argc, char *argv[]);

int main(int argc, char *argv[]) {
  if (auto ec = init(argc, argv)) {
    NSLog(@"failed to initialize application: %d", ec);
    return ec;
  }
  if (acquireCameraPermission() == false) {
    NSLog(@"Failed: %@", @"Camera permission");
    return __LINE__;
  }
  @autoreleasepool {
    NSApp = [NSApplication sharedApplication];

    auto appd = [[AD alloc] init];
    [NSApp setDelegate:appd];

    auto windowd = [[SBD alloc] init];
    auto device = acquireCameraDevice();
    auto window1 = makeWindowForAVCaptureDevice(appd, [device localizedName], device, windowd);
    if (window1 == nil)
      return __LINE__;
    NSLog(@"created window: %@", window1.title);
    return [NSApp run], 0;
  }
}

@implementation AD
- (NSWindow *)makeWindow:(id<NSWindowDelegate>)delegate title:(NSString *)txt contentView:(NSView *)view {
  auto window = [[NSWindow alloc]
      initWithContentRect:view.visibleRect
                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                  backing:NSBackingStoreBuffered
                    defer:YES];
  window.backgroundColor = [NSColor blackColor];
  /// @todo use minimum boundary of the `view`
  window.title = txt;
  [window setDelegate:delegate];
  [window setContentView:view];
  [window makeKeyAndOrderFront:self];
  [window setAcceptsMouseMovedEvents:NO];
  return window;
}
- (void)applicationDidFinishLaunching:(NSNotification *)n {
  NSLog(@"application did finish launching");
}
- (void)applicationWillTerminate:(NSNotification *)n {
  NSLog(@"application will terminate");
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
  return YES;
}
@end
