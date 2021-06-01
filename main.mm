#import "pch.h"

@interface AD : NSObject <NSApplicationDelegate, NSWindowDelegate, //
                          AVCaptureVideoDataOutputSampleBufferDelegate>
@property NSOpenGLContext* context;
@property AVCaptureSession* session;
@end
@implementation AD
- (void)applicationDidFinishLaunching:(NSNotification*)n {
    NSLog(@"application: did finish launching");
}
- (void)applicationWillTerminate:(NSNotification*)n {
    NSLog(@"application: will terminate");
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)app {
    return YES;
}
- (void)windowWillClose:(NSNotification*)notification {
    NSWindow* window = notification.object;
    NSLog(@"window close: %@", window.title);
    // [_session stopRunning];
}
- (void)captureOutput:(AVCaptureOutput*)output
    didOutputSampleBuffer:(CMSampleBufferRef)buffer
           fromConnection:(AVCaptureConnection*)connection {
    CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(buffer);
    CVPixelBufferRetain(pb);
    CVPixelBufferRelease(pb);
    //     const size_t bpr = CVPixelBufferGetBytesPerRow(pb);
    //     const size_t width = CVPixelBufferGetWidth(pb);
    //     const size_t height = CVPixelBufferGetHeight(pb);
    //     const size_t data_size = CVPixelBufferGetDataSize(pb);
    //     // CVPixelBufferLockBaseAddress(pb, 0);
    //     // const void* ptr = CVPixelBufferGetBaseAddress(pb);
    //     // CVPixelBufferUnlockBaseAddress(pb, 0);
    //     const auto format = CVPixelBufferGetPixelFormatType(pb);
    //     switch (format) {
    //     case kCVPixelFormatType_422YpCbCr8: // '2yuv'
    //         break;
    //     case kCVPixelFormatType_422YpCbCr8_yuvs: // 'yuvs'
    //         break;
    //     case kCVPixelFormatType_32BGRA: // 'BGRA'
    //         break;
    //     default:
    //         break;
    //     }
}
- (void)captureOutput:(AVCaptureOutput*)output
    didDropSampleBuffer:(CMSampleBufferRef)buffer
         fromConnection:(AVCaptureConnection*)connection {
    NSLog(@"buffer delegate: %s", "drop");
}
@end

int main(int, char*[]) {
    if (acquireCameraPermission() == false) {
        NSLog(@"Failed: %@", @"Camera permission");
        return __LINE__;
    }
    @autoreleasepool {
        NSApp = [NSApplication sharedApplication];

        auto delegate = [[AD alloc] init];
        [NSApp setDelegate:delegate];

        NSWindow* window = nil;
        AVCaptureSession* session = nil;
        auto const device = acquireCameraDevice();
        if (NSError* err = makeWindowForAVCaptureDevice(
                &window, [device localizedName], &session, device, delegate)) {
            NSLog(@"%@", [err description]);
            return __LINE__;
        }
        delegate.session = session;
        [session startRunning];
        return [NSApp run], 0;
    }
}

NSWindow* makeWindow(id<NSWindowDelegate> delegate, //
                     NSString* title, NSView* view) {
    auto window =
        [[NSWindow alloc] initWithContentRect:view.visibleRect
                                    styleMask:NSWindowStyleMaskTitled |
                                              NSWindowStyleMaskClosable |
                                              NSWindowStyleMaskResizable
                                      backing:NSBackingStoreBuffered
                                        defer:YES];
    window.backgroundColor = [NSColor whiteColor];
    /// @todo use minimum boundary of the `view`
    window.title = title;
    [window setDelegate:delegate];
    [window setContentView:view];
    [window makeKeyAndOrderFront:delegate];
    [window setAcceptsMouseMovedEvents:NO];
    return window;
}
