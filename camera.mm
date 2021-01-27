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
  return [AVCaptureDevice authorizationStatusForMediaType:mtype] == AVAuthorizationStatusAuthorized;
}

AVCaptureDevice *acquireCameraDevice() {
  AVCaptureDeviceDiscoverySession *discovery = [AVCaptureDeviceDiscoverySession
      discoverySessionWithDeviceTypes:[NSArray arrayWithObject:AVCaptureDeviceTypeBuiltInWideAngleCamera]
                            mediaType:AVMediaTypeVideo
                             position:AVCaptureDevicePositionUnspecified];
  for (AVCaptureDevice *camera in [discovery devices]) {
    NSString *name = [camera localizedName];
    NSLog(@"camera: %@", name);
    switch (AVCaptureDevicePosition pos = [camera position]) {
    case AVCaptureDevicePositionBack:
    case AVCaptureDevicePositionFront:
    case AVCaptureDevicePositionUnspecified:
      NSLog(@"position: %ld", pos);
    }
    for (AVCaptureDeviceFormat *fmt : [camera formats]) {
      NSLog(@"format: %@", fmt);
    }
    return camera;
  }
  return nullptr;
}

NSError *configure(AVCaptureSession *session, AVCaptureDevice *device,
                   id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate, NSRect &rect) {
  NSError *err{};
  auto input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&err];
  if (err)
    return err;
  [session beginConfiguration];
  [session addInput:input];
  auto output = [[AVCaptureVideoDataOutput alloc] init];
  [output setSampleBufferDelegate:delegate //
                            queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];
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

NSWindow *makeWindowForAVCaptureDevice(AD *appd, NSString *title, AVCaptureDevice *device, SBD *windowd) {
  if (device == nil) {
    NSLog(@"Failed: %@", @"AVCaptureDevice(Camera)");
    return nil;
  }
  AVCaptureSession *session = [[AVCaptureSession alloc] init];
  NSRect frame{};
  if (NSError *err = configure(session, device, windowd, frame)) {
    NSLog(@"Failed: %@", [err description]);
    return nullptr;
  }
  NSView *view = [[NSView alloc] initWithFrame:frame];
  view.wantsLayer = true;
  AVCaptureVideoPreviewLayer *layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
  layer.frame = frame;
  layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  [view.layer addSublayer:layer];

  NSWindow *window = [appd makeWindow:windowd title:title contentView:view];
  NSLog(@"capture session: start running");
  [session startRunning];
  return window;
}

@implementation SBD
- (id)init:(AVCaptureDevice *)device session:(AVCaptureSession *)session {
  if (self = [super init]) {
    _session = session;
  }
  return self;
}
- (void)consume:(CVPixelBufferRef)pb {
  // const size_t bpr = CVPixelBufferGetBytesPerRow(pb);
  // const size_t width = CVPixelBufferGetWidth(pb);
  // const size_t height = CVPixelBufferGetHeight(pb);
  // const size_t data_size = CVPixelBufferGetDataSize(pb);
  // CVPixelBufferLockBaseAddress(pb, 0);
  // const void* ptr = CVPixelBufferGetBaseAddress(pb);
  // CVPixelBufferUnlockBaseAddress(pb, 0);
  const auto format = CVPixelBufferGetPixelFormatType(pb);
  switch (format) {
  case kCVPixelFormatType_422YpCbCr8:      // '2yuv'
  case kCVPixelFormatType_422YpCbCr8_yuvs: // 'yuvs'
  case kCVPixelFormatType_32BGRA:          // 'BGRA'
  default:
    break;
  }
}
- (void)captureOutput:(AVCaptureOutput *)output
    didOutputSampleBuffer:(CMSampleBufferRef)buffer
           fromConnection:(AVCaptureConnection *)connection {
  CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(buffer);
  CVPixelBufferRetain(pb);
  [self consume:pb];
  CVPixelBufferRelease(pb);
}
- (void)captureOutput:(AVCaptureOutput *)output
    didDropSampleBuffer:(CMSampleBufferRef)buffer
         fromConnection:(AVCaptureConnection *)connection {
  NSLog(@"buffer delegate: %s", "drop");
}
- (void)windowWillClose:(NSNotification *)notification {
  NSWindow *window = notification.object;
  NSLog(@"window close: %@", window.title);
  // stop the session so no more `captureOutput` occurs
  NSLog(@"capture session: stop running");
  [_session stopRunning];
}
@end
