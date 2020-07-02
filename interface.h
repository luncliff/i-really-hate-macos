/**
 * @file interface.h
 * @see C++ 17
 */
#pragma once
#include <filesystem>
#include <memory>
#if defined(__OBJC__)
#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>
#if defined(TARGET_OS_MAC)
#import <AppKit/AppKit.h>
#else
#error "currently TARGET_OS_MAC only"
#endif

class texture_renderer_t;

@protocol OpenGLRenderer
- (GLenum)render:(NSOpenGLContext*)context currentView:(NSOpenGLView*)view;
@end

@interface AD : NSObject <NSApplicationDelegate,                        //
                          AVCaptureVideoDataOutputSampleBufferDelegate, //
                          OpenGLRenderer> {
  @private
    uint16_t count;
    CVPixelBufferRef current;
    GLuint textures[1];
    std::unique_ptr<texture_renderer_t> renderer;
}
@property NSOpenGLContext* context;

- (NSWindow*)makeWindow:(id<NSWindowDelegate>)delegate
                  title:(NSString*)txt
            contentView:(NSView*)view;

@end

NSWindow* makeWindowForOpenGL(AD* appd, NSString* title);
NSWindow* makeWindowForOpenGL(AD* appd, NSString* title,
                              id<OpenGLRenderer> renderer,
                              NSOpenGLContext* context);

NSWindow* makeWindowForMtkView(AD* appd, NSString* title);

AVCaptureDevice* acquireCameraDevice();
bool acquireCameraPermission();
NSWindow* makeWindowForAVCaptureDevice(AD* appd, NSString* title,
                                       AVCaptureDevice* device);
NSWindow* makeWindowForAVCaptureDevice(
    AD* appd, NSString* title, AVCaptureDevice* device,
    id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate);

#endif

namespace fs = std::filesystem;

uint32_t init(int argc, char* argv[]);
