#import "interface.h"

int main(int argc, char* argv[]) {
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
        auto delegate = [[AD alloc] init];
        [NSApp setDelegate:delegate];

        auto const device = acquireCameraDevice();
        auto const window1 = makeWindowForAVCaptureDevice(
            delegate, [device localizedName], device, delegate);
        if (window1 == nil)
            return __LINE__;
        NSLog(@"created window: %@", window1.title);

        auto const window2 = makeWindowForOpenGL(delegate, @"OpenGL", delegate);
        if (window2 == nil)
            return __LINE__;
        NSLog(@"created window: %@", window2.title);

        return [NSApp run], 0;
    }
}

#import <OpenGL/OpenGL.h> // _OPENGL_H
#import <OpenGL/gl.h>     // __gl_h_
#import <OpenGL/glext.h>  // __glext_h_

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

- (void)consume:(CVPixelBufferRef)pb {
    // const size_t bpr = CVPixelBufferGetBytesPerRow(pb);
    // const size_t data_size = CVPixelBufferGetDataSize(pb);
    // CVPixelBufferLockBaseAddress(pb, 0);
    // const void* ptr = CVPixelBufferGetBaseAddress(pb);
    // CVPixelBufferUnlockBaseAddress(pb, 0);
    const auto format = CVPixelBufferGetPixelFormatType(pb);
    switch (format) {
    case kCVPixelFormatType_422YpCbCr8: // '2yuv'
        break;
    case kCVPixelFormatType_422YpCbCr8_yuvs: // 'yuvs'
    case kCVPixelFormatType_32BGRA:          // 'BGRA'
    default:
        return;
    }
    CVPixelBufferRetain(pb);
    auto old = _pixelBuffer;
    _pixelBuffer = pb;
    if (old != nil)
        CVPixelBufferRelease(pb);
}
- (void)captureOutput:(AVCaptureOutput*)output
    didOutputSampleBuffer:(CMSampleBufferRef)buffer
           fromConnection:(AVCaptureConnection*)connection {
    CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(buffer);
    CVPixelBufferRetain(pb);
    [self consume:pb];
    CVPixelBufferRelease(pb);
}
- (void)captureOutput:(AVCaptureOutput*)output
    didDropSampleBuffer:(CMSampleBufferRef)buffer
         fromConnection:(AVCaptureConnection*)connection {
}
- (GLenum)render:(NSOpenGLContext*)context currentView:(NSOpenGLView*)view {
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    CVPixelBufferRef pb = _pixelBuffer;
    _pixelBuffer = nil;
    if (pb != nil) {
        const size_t width = CVPixelBufferGetWidth(pb);
        const size_t height = CVPixelBufferGetHeight(pb);
        glActiveTexture(GL_TEXTURE0);
        const auto target = GL_TEXTURE_RECTANGLE_EXT;
        if (tex == 0) {
            glEnable(GL_TEXTURE_RECTANGLE_EXT);
            glGenTextures(1, &tex);
            glBindTexture(target, tex);
            glTexParameteri(target, GL_TEXTURE_STORAGE_HINT_APPLE,
                            GL_STORAGE_SHARED_APPLE);
            glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(target, tex);
        CVPixelBufferLockBaseAddress(pb, 0);
        const void* ptr = CVPixelBufferGetBaseAddress(pb);
        glTextureRangeAPPLE(target, width * height * 2, ptr);
        CVPixelBufferUnlockBaseAddress(pb, 0);
        CVPixelBufferRelease(pb);
    }
    glFlush();
    return glGetError();
}
@end
