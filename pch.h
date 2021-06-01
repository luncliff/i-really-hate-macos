#pragma once
#include <memory>
#if defined(__APPLE__) & defined(__OBJC__)
#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>
#if defined(TARGET_OS_MAC) & TARGET_OS_MAC
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif
#endif // __APPLE__ & __OBJC__

#include <OpenGL/OpenGL.h> // _OPENGL_H
#include <OpenGL/gl.h>     // __gl_h_

bool acquireCameraPermission() noexcept;
AVCaptureDevice* acquireCameraDevice() noexcept;

#if defined(__OBJC__)
NSWindow* makeWindow(id<NSWindowDelegate> delegate, //
                     NSString* title, NSView* view);

NSError* makeWindowForAVCaptureDevice(
    NSWindow** pwindow, NSString* title, AVCaptureSession** psession,
    AVCaptureDevice* device,
    id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate);
#endif
