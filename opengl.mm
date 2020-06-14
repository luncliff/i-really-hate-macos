#import "interface.h"

#import <OpenGL/OpenGL.h> // _OPENGL_H
#import <OpenGL/gl3.h>    // __gl3_h_
#import <OpenGL/gl3ext.h> // __gl3ext_h_

/// @see https://stackoverflow.com/questions/25981553/cvdisplaylink-with-swift
/// @see https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/
@interface GLV : NSOpenGLView {
  @private
    CVDisplayLinkRef display;
    uint32_t count;
}
@end
@implementation GLV
- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        GLint interval = 1;
        [self.openGLContext setValues:&interval
                         forParameter:NSOpenGLContextParameterSwapInterval];
    }
    count = 0;
    return self;
}
- (CVDisplayLinkRef)getDisplay {
    return display;
}
/// @note the callback won't be invoked in the main thread
static CVReturn callback(CVDisplayLinkRef display, const CVTimeStamp* now,
                         const CVTimeStamp* outputTime, CVOptionFlags iflags,
                         CVOptionFlags* oflags, void* ptr) {
    auto view = reinterpret_cast<GLV*>(ptr);
    auto context = [view openGLContext];
    [context makeCurrentContext];
    [context lock];
    {
        if (auto ec = [view render:CGLGetCurrentContext()])
            NSLog(@"gl error: %5u(%4x)", ec, ec);
        glFlush();
    }
    [context unlock];
    return kCVReturnSuccess;
}
- (void)prepareOpenGL {
    [super prepareOpenGL];
    glClearColor(0, 0, 0, 0);
    // the view will be refreshed with CVDisplay
    CVDisplayLinkCreateWithActiveCGDisplays(&display);
    CVDisplayLinkSetOutputCallback(display, &callback, self);
    CVDisplayLinkStart(display);
}
- (void)reshape { // update viewport
    [super reshape];
    auto context = [self openGLContext];
    [context lock];
    {
        const auto frame = [self frame];
        glViewport(0, 0, frame.size.width, frame.size.height);
        if (auto ec = glGetError())
            NSLog(@"gl error: %5u(%4x)", ec, ec);
    }
    [context unlock];
}
- (GLenum)render:(void*)context {
    count = (count + 1) % 256;
    glClearColor(0, static_cast<float>(count) / 256, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    return glGetError();
}
@end
@interface CVDO : NSObject <NSWindowDelegate>
@property(readonly) GLV* view;
@end
@implementation CVDO
- (id)init:(GLV*)view {
    if (self = [super init]) {
        _view = view;
    }
    return self;
}
- (void)windowWillClose:(NSNotification*)notification {
    NSWindow* window = notification.object;
    NSLog(@"window close: %@", window.title);
    if (auto display = [_view getDisplay]) {
        CVDisplayLinkStop(display);
        CVDisplayLinkRelease(display);
    }
}
@end

/// @see https://developer.apple.com/documentation/appkit/nsopenglview
NSWindow* makeWindowForOpenGL(AD* appd, NSString* title) {
    const auto rect = NSMakeRect(0, 0, 720, 720);
    auto view = [[GLV alloc] initWithFrame:rect];
    auto delegate = [[CVDO alloc] init:view];
    auto window = [appd makeWindow:delegate title:title contentView:view];
    return window;
}
