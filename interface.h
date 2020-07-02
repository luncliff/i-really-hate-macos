/**
 * @file interface.h
 * @see C++ 17
 */
#if defined(__OBJC__)
#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>
#if defined(TARGET_OS_MAC)
#import <AppKit/AppKit.h>
#else
#error "currently TARGET_OS_MAC only"
#endif

@protocol OpenGLRenderer
- (GLenum)render:(NSOpenGLContext*)context currentView:(NSOpenGLView*)view;
@end

@interface AD : NSObject <NSApplicationDelegate,                        //
                          AVCaptureVideoDataOutputSampleBufferDelegate, //
                          OpenGLRenderer> {
  @private
    GLuint tex;
}
@property(atomic, readwrite) CVPixelBufferRef pixelBuffer;

- (NSWindow*)makeWindow:(id<NSWindowDelegate>)delegate
                  title:(NSString*)txt
            contentView:(NSView*)view;
@end

NSWindow* makeWindowForOpenGL(AD* appd, NSString* title);
NSWindow* makeWindowForOpenGL(AD* appd, NSString* title,
                              id<OpenGLRenderer> renderer);

NSWindow* makeWindowForMtkView(AD* appd, NSString* title);

AVCaptureDevice* acquireCameraDevice();
bool acquireCameraPermission();
NSWindow* makeWindowForAVCaptureDevice(AD* appd, NSString* title,
                                       AVCaptureDevice* device);
NSWindow* makeWindowForAVCaptureDevice(
    AD* appd, NSString* title, AVCaptureDevice* device,
    id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate);

#endif

#include <filesystem>
namespace fs = std::filesystem;

uint32_t init(int argc, char* argv[]);
