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
    auto latch = dispatch_group_create();
    dispatch_group_enter(latch);
    [AVCaptureDevice requestAccessForMediaType:mtype
                             completionHandler:[latch](BOOL granted) {
                                 NSLog(@"camera permission: %i", granted);
                                 dispatch_group_leave(latch);
                             }];
    dispatch_group_wait(latch,
                        dispatch_time(DISPATCH_TIME_NOW, //
                                      static_cast<int64_t>(5 * NSEC_PER_SEC)));
    return [AVCaptureDevice authorizationStatusForMediaType:mtype] ==
           AVAuthorizationStatusAuthorized;
}

/// @todo https://developer.apple.com/documentation/avfoundation/avcapturedevicediscoverysession/2361539-discoverysessionwithdevicetypes?language=objc
AVCaptureDevice* acquireCameraDevice() {
    for (AVCaptureDevice* camera in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        const auto name = [camera localizedName];
        NSLog(@"camera: %@", name);
        switch (const auto pos = [camera position]) {
        case AVCaptureDevicePositionBack:
        case AVCaptureDevicePositionFront:
        case AVCaptureDevicePositionUnspecified:
            NSLog(@"position: %@", pos);
        }
        for (auto fmt : [camera formats])
            NSLog(@"format: %@", fmt);

        return camera;
    }
    return nullptr;
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

- (void)consume:(CVPixelBufferRef)pb {
    const size_t bpr = CVPixelBufferGetBytesPerRow(pb);
    const size_t width = CVPixelBufferGetWidth(pb);
    const size_t height = CVPixelBufferGetHeight(pb);
    const size_t data_size = CVPixelBufferGetDataSize(pb);
    // CVPixelBufferLockBaseAddress(pb, 0);
    // const void* ptr = CVPixelBufferGetBaseAddress(pb);
    // CVPixelBufferUnlockBaseAddress(pb, 0);
    const auto format = CVPixelBufferGetPixelFormatType(pb);
    switch (format) {
    case kCVPixelFormatType_422YpCbCr8: // '2yuv'
        break;
    case kCVPixelFormatType_422YpCbCr8_yuvs: // 'yuvs'
        break;
    case kCVPixelFormatType_32BGRA: // 'BGRA'
        break;
    default:
        break;
    }
}
- (void)captureOutput:(AVCaptureOutput*)output
    didOutputSampleBuffer:(CMSampleBufferRef)buffer
           fromConnection:(AVCaptureConnection*)connection {
    CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(buffer);
    CVPixelBufferRetain(pb);
    [self consume:pb];
    CVPixelBufferRelease(pb);
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
    auto input = [[AVCaptureDeviceInput alloc] initWithDevice:device
                                                        error:&err];
    if (err)
        return err;
    [session beginConfiguration];
    [session addInput:input];
    auto output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:delegate //
                              queue:dispatch_get_global_queue(
                                        DISPATCH_QUEUE_PRIORITY_LOW, 0)];
    [session addOutput:output];
    output.videoSettings = @{
        // kCVPixelFormatType_32BGRA 'BGRA'
        // kCVPixelFormatType_422YpCbCr8 '2yuv'
        // kCVPixelFormatType_422YpCbCr8_yuvs 'yuvs'
        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_422YpCbCr8),
        (id)kCVPixelBufferMetalCompatibilityKey : @(YES),
        (id)kCVPixelBufferOpenGLCompatibilityKey : @(YES),
    };
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    rect = NSMakeRect(0, 0, 1280, 720);
    [session commitConfiguration];
    return nil;
}

NSWindow* makeWindowForAVCaptureDevice(AD* appd, NSString* title,
                                       AVCaptureDevice* device) {
    if (device == nil) {
        NSLog(@"Failed: %@", @"AVCaptureDevice(Camera)");
        return nil;
    }
    auto session = [[AVCaptureSession alloc] init];
    auto delegate = [[SBD alloc] init:device session:session];
    auto frame = NSMakeRect(0, 0, 640, 480);
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
    NSLog(@"capture session: start running");
    [session startRunning];
    return window;
}

NSWindow* makeWindowForAVCaptureDevice(
    AD* appd, NSString* title, AVCaptureDevice* device,
    id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate) {
    if (device == nil) {
        NSLog(@"Failed: %@", @"AVCaptureDevice(Camera)");
        return nil;
    }
    auto session = [[AVCaptureSession alloc] init];
    auto frame = NSMakeRect(0, 0, 640, 480);
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

    auto windowd = [[SBD alloc] init:device session:session];
    auto window = [appd makeWindow:windowd title:title contentView:view];
    NSLog(@"capture session: start running");
    [session startRunning];
    return window;
}
