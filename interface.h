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

@interface AD : NSObject <NSApplicationDelegate>
- (NSWindow*)makeWindow:(id<NSWindowDelegate>)delegate
                  title:(NSString*)txt
            contentView:(NSView*)view;
@end

NSWindow* makeWindowForOpenGL(AD* appd, NSString* title);
NSWindow* makeWindowForMtkView(AD* appd, NSString* title, void* context);
NSWindow* makeWindowForAVCaptureSession(AD* appd, NSString* title,
                                        AVCaptureSession* session);

AVCaptureDevice* acquireCameraDevice();
bool acquireCameraPermission();
#endif

#include <filesystem>
namespace fs = std::filesystem;
