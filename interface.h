#pragma once
#if defined(__OBJC__)
#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>
#if defined(TARGET_OS_MAC)
#import <AppKit/AppKit.h>
#else
#error "currently TARGET_OS_MAC only"
#endif
@interface SBD : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, //
                           NSWindowDelegate>
@property(readonly) AVCaptureSession *session;
@end

@interface AD : NSObject <NSApplicationDelegate> {
@private
  uint16_t count;
}
- (NSWindow *)makeWindow:(id<NSWindowDelegate>)delegate title:(NSString *)txt contentView:(NSView *)view;
@end

NSWindow *makeWindowForMtkView(AD *appd, NSString *title);

AVCaptureDevice *acquireCameraDevice();
bool acquireCameraPermission();
NSWindow *makeWindowForAVCaptureDevice(AD *appd, NSString *title, AVCaptureDevice *device, SBD *windowd);

#endif
