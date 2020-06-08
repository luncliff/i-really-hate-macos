#import "interface.h"

@implementation VD
- (id)initWithMetalKitView:(MTKView*)view {
    if ([self init]) {
        // ...
    }
    return self;
}
// - (void)viewDidLoad { // NSViewController
//     [super viewDidLoad];
//     NSLog(@"view did load");
// }
- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {
}
- (void)drawInMTKView:(MTKView*)view {
}
@end

NSWindow* makeWindowForMtkView(AD* appd, NSString* title, void* context) {
    // will run with Metal
    auto device = MTLCreateSystemDefaultDevice();
    if (device == nil) {
        NSLog(@"Metal is not supported on this machine");
        return nil;
    }
    // fixed size for convenience
    const auto rect = NSMakeRect(0, 0, 720, 720);
    auto view = [[MTKView alloc] initWithFrame:rect device:device];
    auto renderer = [[VD alloc] initWithMetalKitView:view];
    [renderer mtkView:view drawableSizeWillChange:view.bounds.size];
    [view setDelegate:renderer];
    // view is ready. spawn a new window and assign context
    auto windowd = [[WD alloc] init];
    auto window = [appd makeWindow:windowd title:title contentView:view];
    [windowd scheduleMTKView:view context:context];
    return window;
}
