#
# Usage - iOS
#   cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=../ios.toolchain.cmake -DDEPLOYMENT_TARGET=10.15 -DPLATFORM=SIMULATOR64 -DENABLE_BITCODE=false -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=123456789A
#   cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=../ios.toolchain.cmake -DDEPLOYMENT_TARGET=10.15 -DPLATFORM=OS64
#
cmake_minimum_required(VERSION 3.18)
project(hate_this LANGUAGES CXX OBJCXX)
if(NOT APPLE)
    message(FATAL_ERROR "expect APPLE platform")
endif()
message(STATUS "using Apple: ${CMAKE_OSX_SYSROOT}")
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
    message(FATAL_ERROR "requires CMAKE_INSTALL_PREFIX")
endif()
option(BUILD_TESTING "Build with XCTest" OFF)

add_executable(damn_app
    interface.h
    camera.mm
)

set_target_properties(damn_app
PROPERTIES
    CXX_STANDARD 17
    OBJCXX_STANDARD 17
    MACOSX_BUNDLE   true
    XCODE_ATTRIBUTE_ENABLE_TESTABILITY true
    # XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED OFF
    # XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "dev.luncliff.damn-app"
)

target_include_directories(damn_app
PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_INSTALL_PREFIX}/include
)

target_compile_definitions(damn_app
PRIVATE
    GL_SILENCE_DEPRECATION
)

target_compile_options(damn_app
PRIVATE
    -std=c++2a -stdlib=libc++ -Wall -Wextra
)

target_link_directories(damn_app
PRIVATE
    ${CMAKE_INSTALL_PREFIX}/lib
)

target_link_libraries(damn_app
PRIVATE
    ${CMAKE_DL_LIBS}
    "-framework CoreVideo" "-framework AVFoundation" "-framework CoreMedia" "-framework Metal" "-framework MetalKit" 
)
if(IOS)
    target_sources(damn_app
    PRIVATE
        main-iphone.mm
    )
    set_target_properties(damn_app
    PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST    ${CMAKE_CURRENT_SOURCE_DIR}/Info-iphone.plist
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY  "1,2"
    )
    target_link_libraries(damn_app
    PRIVATE
        "-framework UIKit"
    )
else()
    target_sources(damn_app
    PRIVATE
        main.mm native.cpp metal.mm
    )
    set_target_properties(damn_app
    PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST    ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
    )
    target_link_libraries(damn_app
    PRIVATE
        "-framework AppKit"
    )
endif()

# include(BundleUtilities)
install(TARGETS damn_app
        BUNDLE DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
)

if(NOT CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
    return()
elseif(NOT BUILD_TESTING)
    return()
endif()
enable_testing()
find_package(XCTest REQUIRED)

list(APPEND src
    native_test.mm
    # ...
)
source_group(test_case
FILES
    ${src}
)

xctest_add_bundle(damn_app_test damn_app
    Info.plist ${src}
)

set_target_properties(damn_app_test
PROPERTIES
    OBJCXX_STANDARD 17
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
)

target_include_directories(damn_app_test
PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR} ${XCTest_INCLUDE_DIRS}
    ${CMAKE_INSTALL_PREFIX}/include
)

target_link_directories(damn_app_test
PRIVATE
    ${CMAKE_INSTALL_PREFIX}/lib
)

target_link_libraries(damn_app_test
PRIVATE
    ${XCTest_LIBRARIES} "-framework CoreMedia"
)

target_compile_options(damn_app_test
PRIVATE
    -std=c++2a -stdlib=libc++ -Wall -Wextra
)
