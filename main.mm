#import "opengl_es.h"

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

        NSOpenGLPixelFormatAttribute attrs[] = {
            NSOpenGLPFAColorSize, 32,  //
            NSOpenGLPFADepthSize, 24,  //
            NSOpenGLPFAStencilSize, 8, //
            NSOpenGLPFAAccelerated,
            // GLKit also requires OpenGL 3.2 Core
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core, 0};
        auto formats = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
        auto context = [[NSOpenGLContext alloc] initWithFormat:formats
                                                  shareContext:nil];
        auto delegate = [[AD alloc] init];
        delegate.context = context;
        [NSApp setDelegate:delegate];

        auto const device = acquireCameraDevice();
        auto const window1 = makeWindowForAVCaptureDevice(
            delegate, [device localizedName], device, delegate);
        if (window1 == nil)
            return __LINE__;
        NSLog(@"created window: %@", window1.title);

        auto const window2 =
            makeWindowForOpenGL(delegate, @"OpenGL", delegate, context);
        if (window2 == nil)
            return __LINE__;
        NSLog(@"created window: %@", window2.title);
        return [NSApp run], 0;
    }
}

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

- (void)captureOutput:(AVCaptureOutput*)output
    didOutputSampleBuffer:(CMSampleBufferRef)buffer
           fromConnection:(AVCaptureConnection*)connection {
    CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(buffer);
    const auto format = CVPixelBufferGetPixelFormatType(pb);
    switch (format) {
    case kCVPixelFormatType_422YpCbCr8:      // '2yuv'
    case kCVPixelFormatType_422YpCbCr8_yuvs: // 'yuvs'
        break;
    default:
        return;
    }

    if (count % 15 == 0) {
        CVPixelBufferRetain(pb);
        current = pb;
        count = 0;
    }
    //    [_context makeCurrentContext];
    //    [_context lock];
    //    [_context unlock];
}
- (void)captureOutput:(AVCaptureOutput*)output
    didDropSampleBuffer:(CMSampleBufferRef)buffer
         fromConnection:(AVCaptureConnection*)connection {
    CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(buffer);
    if (pb == nullptr)
        return;
    auto desc = [[MTLTextureDescriptor alloc] init];
    desc.pixelFormat = MTLPixelFormatBGRG422; // for '2vuy'
    desc.width = CVPixelBufferGetWidth(pb);
    desc.height = CVPixelBufferGetHeight(pb);
    auto device = MTLCreateSystemDefaultDevice();
    auto texture = [device newTextureWithDescriptor:desc];
    [desc release];
    const MTLRegion region{MTLOrigin{0, 0, 0},
                           MTLSize{desc.width, desc.height, 1}};
    const auto flags = kCVPixelBufferLock_ReadOnly;
    CVPixelBufferLockBaseAddress(pb, flags);
    [texture replaceRegion:region // 2D non-mipmapped textures
               mipmapLevel:0
                 withBytes:CVPixelBufferGetBaseAddress(pb)
               bytesPerRow:CVPixelBufferGetBytesPerRow(pb)];
    CVPixelBufferUnlockBaseAddress(pb, flags);
    [texture release];
}

- (GLenum)render:(NSOpenGLContext*)context currentView:(NSOpenGLView*)view {
    glClearColor(0.10f, static_cast<float>(count++ % 255) / 255, 0.10f, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    if (textures[0] == 0) {
        glGenTextures(1, textures);
        return glGetError();
    }
    auto pb = current;
    if (pb == nullptr)
        return glGetError();
    if (auto tex = textures[0]) {
        glActiveTexture(GL_TEXTURE0);
        const auto target = GL_TEXTURE_2D; // Sampler2D
        glBindTexture(target, tex);
        const auto format = GL_RGB_422_APPLE;
        const auto internal = GL_RGB8; // 0x8A51; // RGB_RAW_422_APPLE;
        // const auto type = CVPixelBufferGetPixelFormatType(pb) ==
        //                           kCVPixelFormatType_422YpCbCr8_yuvs
        //                       ? GL_UNSIGNED_SHORT_8_8_REV_APPLE
        //                       : GL_UNSIGNED_SHORT_8_8_APPLE;
        const auto type = GL_UNSIGNED_SHORT_8_8_APPLE; // 2 component
        const auto w = CVPixelBufferGetWidth(pb);
        const auto h = CVPixelBufferGetHeight(pb);
        constexpr auto level = 0, border = 0;
        const auto flags = kCVPixelBufferLock_ReadOnly;
        CVPixelBufferLockBaseAddress(pb, flags);
        const void* ptr = CVPixelBufferGetBaseAddress(pb);
        glTexImage2D(target, level, internal, w, h, border, format, type, ptr);
        CVPixelBufferUnlockBaseAddress(pb, flags);
    }
    if (auto ec = glGetError())
        NSLog(@"opengl error: %u(%x)", ec, ec);
    if (renderer == nullptr)
        renderer = make_tex2d_renderer();
    if (GLuint tex = textures[0]) {
        if (auto ec = renderer->render(context, tex, GL_TEXTURE_2D))
            return ec;
    }
    glFlush();
    return glGetError();
}
@end
