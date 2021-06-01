#import "pch.h"

bool acquireCameraPermission() noexcept {
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
AVCaptureDevice* acquireCameraDevice() noexcept {
    for (AVCaptureDevice* camera in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        const auto name = [camera localizedName];
        NSLog(@"camera: %@", name);
        switch (const auto pos = [camera position]) {
        case AVCaptureDevicePositionBack:
            NSLog(@"position: %@", @"Back");
        case AVCaptureDevicePositionFront:
            NSLog(@"position: %@", @"Front");
        case AVCaptureDevicePositionUnspecified:
            NSLog(@"position: %@", @"Unspecified");
        }
        for (id fmt : [camera formats])
            NSLog(@"format: %@", fmt);
        return camera;
    }
    return nullptr;
}

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

NSError* makeWindowForAVCaptureDevice(
    NSWindow** pwindow, NSString* title, AVCaptureSession** psession,
    AVCaptureDevice* device,
    id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate) {
    auto session = [[AVCaptureSession alloc] init];
    *psession = session;
    auto frame = NSMakeRect(0, 0, 640, 480);
    if (auto err = configure(session, device, delegate, frame)) {
        NSLog(@"Failed: %@", [err description]);
        return err;
    }
    auto view = [[NSView alloc] initWithFrame:frame];
    view.wantsLayer = true;
    auto layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    layer.frame = frame;
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [view.layer addSublayer:layer];
    *pwindow = makeWindow(nil, title, view);
    return nil;
}
