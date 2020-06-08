/**
 * @file interface.h
 * @see C++ 17
 */
#if defined(__OBJC__)
#import <AVFoundation/AVFoundation.h>
#import <AppKit/AppKit.h>
#import <MetalKit/MetalKit.h>

@interface VD : NSObject <MTKViewDelegate>
@end

@interface WD : NSObject <NSWindowDelegate> {
  @private
    NSTimer* timer; /// @see http://blog.weirdx.io/post/877
}
@end

@interface AD : NSObject <NSApplicationDelegate>
@end

NSWindow* makeWindowForMtkView(AD* appd, NSString* title, void* context);
NSWindow* makeWindowForAVCaptureSession(AD* appd, NSString* title,
                                        AVCaptureSession* session);

AVCaptureDevice* acquireCameraDevice();
#endif
#include <filesystem>

namespace fs = std::filesystem;

void acquireCameraPermission();

int init(int argc, char* argv[]);
