#pragma once
#if defined(__OBJC__)
#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>


#else
#import <AppKit/AppKit.h>
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
NSWindow *makeWindowForAVCaptureDevice(AD *appd, NSString *title, AVCaptureDevice *device, SBD *windowd);
#endif

AVCaptureDevice *acquireCameraDevice();
bool acquireCameraPermission();

#endif
