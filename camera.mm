#import "interface.h"

void acquireCameraPermission() {
    switch (
        [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
    case AVAuthorizationStatusAuthorized:
        NSLog(@"camera permission granted");
        return;
    case AVAuthorizationStatusNotDetermined:
        break;
    default:
        NSLog(@"need a permission grant to access camera");
        return exit(__LINE__);
    }
    // request permission and wait for it
    auto group = dispatch_group_create();
    dispatch_group_enter(group);
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                             completionHandler:[group](BOOL granted) {
                                 NSLog(@"camera ?: %d", granted);
                                 dispatch_group_leave(group);
                             }];
    dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, //
                                             (int64_t)(5.0 * NSEC_PER_SEC)));
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

NSWindow* makeWindowForAVCaptureSession(AD* appd, NSString* title,
                                        AVCaptureSession* session) {
    acquireCameraPermission();
    auto device = acquireCameraDevice();
    if (device == nil) {
        NSLog(@"Failed to acquire AVCaptureDevice(Camera)");
        return nil;
    }
    [session beginConfiguration];
    {
        auto input = [[AVCaptureDeviceInput alloc] initWithDevice:device
                                                            error:nil];
        [session addInput:input];
    }
    {
        auto output = [[AVCaptureVideoDataOutput alloc] init];
        [session addOutput:output];
        output.videoSettings = @{
            (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
        };
    }
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    [session commitConfiguration];

    const auto rect = NSMakeRect(0, 0, 1280, 720);
    auto view = [[NSView alloc] initWithFrame:rect];
    view.wantsLayer = true;
    auto layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    layer.frame = rect;
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [view.layer addSublayer:layer];

    auto windowd = [[WD alloc] init];
    auto window = [appd makeWindow:windowd title:title contentView:view];
    NSLog(@"capture session: start running");
    [session startRunning];
    /// @todo stop the session when closing
    // NSLog(@"capture session: stop running");
    // [session stopRunning];
    return window;
}
