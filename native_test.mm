#import <XCTest/XCTest.h>

@interface TestCase1 : XCTestCase
@end
@implementation TestCase1 {
  // ...
}
- (void)setUp {
  self.continueAfterFailure = false;
  XCTAssertTrue(nullptr == nullptr);
}
- (void)tearDown {
  // ...
}
- (void)test1 {
  XCTAssertEqual(1, 1);
}
@end
