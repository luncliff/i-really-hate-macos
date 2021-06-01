#import <XCTest/XCTest.h>
#if defined(__APPLE__)
#include <OpenGL/OpenGL.h> // _OPENGL_H
#include <OpenGL/gl.h>     // __gl_h_
// #include <OpenGL/glext.h>  // __glext_h_
// #define GL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED
// #include <OpenGL/gl3.h>    // __gl3_h_
// #include <OpenGL/gl3ext.h> // __gl3ext_h_
#endif
#include <system_error>

class CGLErrorCategory final : public std::error_category {
    const char* name() const noexcept {
        return "CGLErrorCategory";
    }
    std::string message(int ec) const {
        switch (ec) {
        case kCGLNoError:
            return "no error";
        case kCGLBadAttribute:
            return "invalid pixel format attribute";
        case kCGLBadProperty:
            return "invalid renderer property";
        case kCGLBadPixelFormat:
            return "invalid pixel format";
        case kCGLBadRendererInfo:
            return "invalid renderer info";
        case kCGLBadContext:
            return "invalid context";
        case kCGLBadDrawable:
            return "invalid drawable";
        case kCGLBadDisplay:
            return "invalid graphics device";
        case kCGLBadState:
            return "invalid context state";
        case kCGLBadValue:
            return "invalid numerical value";
        case kCGLBadMatch:
            return "invalid share context";
        case kCGLBadEnumeration:
            return "invalid enumerant";
        case kCGLBadOffScreen:
            return "invalid offscreen drawable";
        case kCGLBadFullScreen:
            return "invalid fullscreen drawable";
        case kCGLBadWindow:
            return "invalid window";
        case kCGLBadAddress:
            return "invalid pointer";
        case kCGLBadCodeModule:
            return "invalid code module";
        case kCGLBadAlloc:
            return "invalid memory allocation";
        case kCGLBadConnection:
            return "invalid CoreGraphics connection";
        default:
            return "unknwon CGLError value";
        }
    }
};

CGLErrorCategory errors{};

/// @note CGL is deprecated since 10.14
class CGL final {
    CGLPixelFormatObj format;
    CGLContextObj handle;

  public:
    explicit CGL(const CGLPixelFormatAttribute* attrs = nullptr,
                 CGLContextObj shared = NULL) noexcept(false) {
        const CGLPixelFormatAttribute basic[]{
            kCGLPFAPBuffer, kCGLPFASupportsAutomaticGraphicsSwitching,
            kCGLPFAAllowOfflineRenderers, (CGLPixelFormatAttribute)NULL};
        if (attrs == nullptr)
            attrs = basic;
        GLint count = 0;
        if (auto ec = CGLChoosePixelFormat(attrs, &format, &count))
            throw std::error_code{ec, errors};
        if (auto ec = CGLCreateContext(format, shared, &handle))
            throw std::error_code{ec, errors};
    }
    ~CGL() noexcept {
        CGLDestroyPixelFormat(format);
        CGLClearDrawable(handle);
        CGLDestroyContext(handle);
    }

    /// @return CGLError
    uint32_t resume() noexcept(false) {
        return static_cast<uint32_t>(CGLSetCurrentContext(handle));
    }
    void suspend() noexcept {
        CGLSetCurrentContext(NULL);
    }
};

@interface TestCase1 : XCTestCase
@end
@implementation TestCase1 {
    // ...
}
- (void)setUp {
    self.continueAfterFailure = false;
    XCTAssertTrue(nullptr == nullptr);
}
- (void)tearDown {
    // ...
}
- (void)test1 {
    XCTAssertEqual(1, 1);
}
@end
