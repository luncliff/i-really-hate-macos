#import <UIKit/UIKit.h>

@interface VC : UIViewController
@end
@implementation VC
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"didReceiveMemoryWarning");
}
@end

@interface AD : UIResponder <UIApplicationDelegate>
@property(strong, nonatomic) UIWindow* window;
@end
@implementation AD
- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)options {
    NSLog(@"didFinishLaunchingWithOptions");
    const auto bounds = [[UIScreen mainScreen] bounds];
    _window = [[UIWindow alloc] initWithFrame:bounds];
    _window.rootViewController = [[VC alloc] init];
    _window.backgroundColor = UIColor.blueColor;
    [_window makeKeyAndVisible];
    return YES;
}
- (void)applicationWillResignActive:(UIApplication*)application {
    NSLog(@"applicationWillResignActive");
}
- (void)applicationDidEnterBackground:(UIApplication*)application {
    NSLog(@"applicationDidEnterBackground");
}
- (void)applicationWillEnterForeground:(UIApplication*)application {
    NSLog(@"applicationWillEnterForeground");
}
- (void)applicationDidBecomeActive:(UIApplication*)application {
    NSLog(@"applicationDidBecomeActive");
    auto view = [[UIView alloc] initWithFrame:[_window frame]];
    view.backgroundColor = UIColor.greenColor;
    view.alpha = 0.500f;
    [_window insertSubview:view atIndex:0];
}
- (void)applicationWillTerminate:(UIApplication*)application {
    NSLog(@"applicationWillTerminate");
}
@end

int main(int argc, char* argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
                                 NSStringFromClass([AD class]));
    }
}
