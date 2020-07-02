#import "interface.h"

@interface MVD : NSObject <MTKViewDelegate, NSWindowDelegate>
@property(assign) NSTimer* timer; /// @see http://blog.weirdx.io/post/877
@property(readonly) id<MTLDevice> device;
@end
@implementation MVD
- (id)init:(id<MTLDevice>)device {
    if (self = [super init]) {
        _device = device;
    }
    return self;
}
- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {
    NSLog(@"view: %@", [view className]);
    if (NSWindow* window = [view window]) {
        NSLog(@"window: %@", [window className]);
    }
    if (CALayer* layer = [view layer]) {
        NSLog(@"layer: %@", [layer className]);
    }
}
- (void)drawInMTKView:(MTKView*)view {
}
- (void)windowWillClose:(NSNotification*)notification {
    if (_timer)
        [_timer invalidate];
    NSWindow* window = notification.object;
    NSLog(@"window close: %@", window.title);
}
- (NSSize)windowWillResize:(NSWindow*)window toSize:(NSSize)size {
    NSLog(@"window will resize: w %.2f h %.2f", size.width, size.height);
    return size;
}
/// @todo consider using `NSDictionary` for context
- (void)schedule {
    const auto count = 2u; // check 2 times in 1 second.
    _timer = [NSTimer scheduledTimerWithTimeInterval:(1.0f / count)
                                              target:self
                                            selector:@selector(updateWithTimer:)
                                            userInfo:self
                                             repeats:YES];
    NSLog(@"window delegate: scheduled");
}
- (void)updateWithTimer:(NSTimer*)_ {
    NSLog(@"MTKViewDelegate delegate: updated");
}
@end

NSWindow* makeWindowForMtkView(AD* appd, NSString* title) {
    // will run with Metal
    auto const device = MTLCreateSystemDefaultDevice();
    if (device == nil) {
        NSLog(@"Metal is not supported on this machine");
        return nil;
    }
    auto renderer = [[MVD alloc] init:device];
    // fixed size for convenience
    const auto rect = NSMakeRect(0, 0, 720, 720);
    auto view = [[MTKView alloc] initWithFrame:rect device:device];
    [renderer mtkView:view drawableSizeWillChange:view.bounds.size];
    [view setDelegate:renderer];
    // view is ready. spawn a new window and assign context
    auto window = [appd makeWindow:renderer title:title contentView:view];
    [renderer schedule];
    return window;
}
