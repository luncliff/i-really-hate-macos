#import "interface.h"

#import <OpenGL/OpenGL.h> // _OPENGL_H
// #import <OpenGL/gl3.h>    // __gl3_h_
// #import <OpenGL/gl3ext.h> // __gl3ext_h_
#import <OpenGL/gl.h>    // __gl_h_
#import <OpenGL/glext.h> // __glext_h_

/// @see https://stackoverflow.com/questions/25981553/cvdisplaylink-with-swift
/// @see https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/
@interface GLV : NSOpenGLView <NSWindowDelegate, OpenGLRenderer> {
  @private
    CVDisplayLinkRef display;
    uint32_t count;
}
@property id<OpenGLRenderer> renderer;
@end
@implementation GLV
- (id)initWithFrame:(NSRect)frame
      sharedContext:(nullable NSOpenGLContext*)sharedContext {
    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFAColorSize, 32,  //
        NSOpenGLPFADepthSize, 24,  //
        NSOpenGLPFAStencilSize, 8, //
        NSOpenGLPFAAccelerated,
        // GLKit also requires OpenGL 3.2 Core
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core, 0};
    auto formats = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    auto context = [[NSOpenGLContext alloc] initWithFormat:formats
                                              shareContext:sharedContext];
    if (self = [super initWithFrame:frame pixelFormat:formats]) {
        [self setOpenGLContext:context];
        GLint interval = 1;
        [context setValues:&interval
              forParameter:NSOpenGLContextParameterSwapInterval];
    }
    _renderer = self;
    return self;
}
- (void)windowWillClose:(NSNotification*)notification {
    NSWindow* window = notification.object;
    NSLog(@"window close: %@", window.title);
    CVDisplayLinkStop(display);
    CVDisplayLinkRelease(display);
}

/// @note the callback won't be invoked in the main thread
static CVReturn callback(CVDisplayLinkRef display, const CVTimeStamp* now,
                         const CVTimeStamp* otime, CVOptionFlags iflags,
                         CVOptionFlags* oflags, void* ptr) {
    auto view = reinterpret_cast<GLV*>(ptr);
    auto context = [view openGLContext];
    [context makeCurrentContext];
    [context lock];
    if (auto ec = [view->_renderer render:context currentView:view])
        NSLog(@"gl error: %5u(%4x)", ec, ec);
    [context unlock];
    return kCVReturnSuccess;
}
- (void)prepareOpenGL {
    NSLog(@"prepareOpenGL");
    [super prepareOpenGL];
    // CGL configuration
    auto const context = [[self openGLContext] CGLContextObj];
    CGLDisable(context, kCGLCEMPEngine);
    // OpenGL informations
    NSLog(@"GL_VERSION: %s", glGetString(GL_VERSION));
    NSLog(@"GL_RENDERER: %s", glGetString(GL_RENDERER));
    NSLog(@"GL_VENDOR: %s", glGetString(GL_VENDOR));
    NSLog(@"GL_SHADING_LANGUAGE_VERSION: %s",
          glGetString(GL_SHADING_LANGUAGE_VERSION));
    // the view will be refreshed with CVDisplay
    CVDisplayLinkCreateWithActiveCGDisplays(&display);
    CVDisplayLinkSetOutputCallback(display, &callback, self);
    CVDisplayLinkStart(display);
}
- (void)reshape { // update viewport
    NSLog(@"reshape");
    [super reshape];
    auto context = [self openGLContext];
    [context lock];
    const auto frame = [self frame];
    glViewport(0, 0, frame.size.width, frame.size.height);
    [context unlock];
}
- (GLenum)render:(NSOpenGLContext*)context currentView:(NSOpenGLView*)view {
    count = (count + 1) % 256;
    glClearColor(0, static_cast<float>(count) / 256, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glFlush();
    return glGetError();
}
@end

/// @see https://developer.apple.com/documentation/appkit/nsopenglview
NSWindow* makeWindowForOpenGL(AD* appd, NSString* title) {
    const auto rect = NSMakeRect(0, 0, 720, 720);
    auto view = [[GLV alloc] initWithFrame:rect sharedContext:nil];
    auto window = [appd makeWindow:view title:title contentView:view];
    return window;
}
NSWindow* makeWindowForOpenGL(AD* appd, NSString* title,
                              id<OpenGLRenderer> renderer) {
    const auto rect = NSMakeRect(0, 0, 720, 720);
    auto view = [[GLV alloc] initWithFrame:rect sharedContext:nil];
    view.renderer = renderer;
    auto window = [appd makeWindow:view title:title contentView:view];
    return window;
}

auto make_offscreen_context(uint32_t& ec) noexcept(false)
    -> std::shared_ptr<void> {
    CGLPixelFormatAttribute attrs[] = {
        // kCGLPFAOffScreen, // bad attribute
        kCGLPFAAccelerated,
        kCGLPFAOpenGLProfile,
        (CGLPixelFormatAttribute)kCGLOGLPVersion_3_2_Core,
        kCGLPFAColorSize,
        (CGLPixelFormatAttribute)32,
        (CGLPixelFormatAttribute)NULL};
    CGLPixelFormatObj pixel_format{};
    GLint num_pixel_format{};
    if ((ec = CGLChoosePixelFormat(attrs, &pixel_format, &num_pixel_format))) {
        return nullptr;
    }
    CGLContextObj context{};
    if ((ec = CGLCreateContext(pixel_format, NULL, &context))) {
        return nullptr;
    }
    if ((ec = CGLDestroyPixelFormat(pixel_format))) {
        return nullptr;
    }
    if ((ec = CGLSetCurrentContext(context))) {
        return nullptr;
    }
    return std::shared_ptr<void>{context, [context](void*) {
                                     CGLSetCurrentContext(NULL);
                                     CGLClearDrawable(context);
                                     CGLDestroyContext(context);
                                 }};
}
