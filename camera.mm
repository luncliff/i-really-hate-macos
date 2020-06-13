#import "interface.h"

bool acquireCameraPermission() {
    const auto mtype = AVMediaTypeVideo;
    switch ([AVCaptureDevice authorizationStatusForMediaType:mtype]) {
    case AVAuthorizationStatusAuthorized:
        return true;
    case AVAuthorizationStatusNotDetermined:
        break;
    default:
        return false;
    }
    // request permission and wait for it
    auto group = dispatch_group_create();
    dispatch_group_enter(group);
    [AVCaptureDevice requestAccessForMediaType:mtype
                             completionHandler:[group](BOOL granted) {
                                 NSLog(@"camera permission: %i", granted);
                                 dispatch_group_leave(group);
                             }];
    dispatch_group_wait(group,
                        dispatch_time(DISPATCH_TIME_NOW, //
                                      static_cast<int64_t>(5 * NSEC_PER_SEC)));
    return [AVCaptureDevice authorizationStatusForMediaType:mtype] ==
           AVAuthorizationStatusAuthorized;
}

/// @todo https://developer.apple.com/documentation/avfoundation/avcapturedevicediscoverysession/2361539-discoverysessionwithdevicetypes?language=objc
AVCaptureDevice* acquireCameraDevice() {
    for (AVCaptureDevice* camera in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        const auto pos = [camera position];
        NSLog(@"camera position: %ld", pos);
        switch (pos) {
        case AVCaptureDevicePositionBack:
            continue;
        case AVCaptureDevicePositionFront:
        case AVCaptureDevicePositionUnspecified:
            return camera;
        }
    }
    return nil;
}

@interface SBD : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, //
                           NSWindowDelegate>
@property(readonly) AVCaptureSession* session;
@end
@implementation SBD
- (id)init:(AVCaptureDevice*)device session:(AVCaptureSession*)session {
    if (self = [super init]) {
        _session = session;
    }
    return self;
}
- (void)start {
    NSLog(@"capture session: start running");
    [_session startRunning];
}
- (void)captureOutput:(AVCaptureOutput*)output
    didOutputSampleBuffer:(CMSampleBufferRef)buffer
           fromConnection:(AVCaptureConnection*)connection {
    NSLog(@"buffer delegate: %s", "output");
    CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(buffer);
    CVPixelBufferLockBaseAddress(pb, 0);
    const void* ptr = CVPixelBufferGetBaseAddress(pb);
    const size_t bpr = CVPixelBufferGetBytesPerRow(pb);
    const size_t width = CVPixelBufferGetWidth(pb);
    const size_t height = CVPixelBufferGetHeight(pb);
    CVPixelBufferUnlockBaseAddress(pb, 0);
}
- (void)captureOutput:(AVCaptureOutput*)output
    didDropSampleBuffer:(CMSampleBufferRef)buffer
         fromConnection:(AVCaptureConnection*)connection {
    NSLog(@"buffer delegate: %s", "drop");
}
- (void)windowWillClose:(NSNotification*)notification {
    NSWindow* window = notification.object;
    NSLog(@"window close: %@", window.title);
    // stop the session so no more `captureOutput` occurs
    NSLog(@"capture session: stop running");
    [_session stopRunning];
}
@end

NSError* configure(AVCaptureSession* session, AVCaptureDevice* device,
                   id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate,
                   NSRect& rect) {
    NSError* err{};
    [session beginConfiguration];
    {
        auto input = [[AVCaptureDeviceInput alloc] initWithDevice:device
                                                            error:&err];
        if (err)
            goto onError;
        [session addInput:input];
    }
    {
        auto output = [[AVCaptureVideoDataOutput alloc] init];
        [output setSampleBufferDelegate:delegate //
                                  queue:dispatch_get_global_queue(
                                            DISPATCH_QUEUE_PRIORITY_LOW, 0)];
        [session addOutput:output];
        output.videoSettings = @{
            (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
        };
    }
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    rect = NSMakeRect(0, 0, 1280, 720);
onError:
    [session commitConfiguration];
    return err;
}

NSWindow* makeWindowForAVCaptureSession(AD* appd, NSString* title,
                                        AVCaptureSession* session) {
    if (acquireCameraPermission() == false) {
        NSLog(@"Failed: %@", @"Camera permission");
        return nil;
    }
    auto const device = acquireCameraDevice();
    if (device == nil) {
        NSLog(@"Failed: %@", @"AVCaptureDevice(Camera)");
        return nil;
    }
    auto delegate = [[SBD alloc] init:device session:session];
    auto frame = NSMakeRect(0, 0, 1280, 720);
    if (auto err = configure(session, device, delegate, frame)) {
        NSLog(@"Failed: %@", [err description]);
        return nullptr;
    }

    auto view = [[NSView alloc] initWithFrame:frame];
    view.wantsLayer = true;
    auto layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    layer.frame = frame;
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [view.layer addSublayer:layer];

    auto window = [appd makeWindow:delegate title:title contentView:view];
    [delegate start];
    return window;
}
