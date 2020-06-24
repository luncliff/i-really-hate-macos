cmake_minimum_required(VERSION 3.8)
project(hate_this LANGUAGES CXX OBJCXX)

if(NOT APPLE)
    message(FATAL_ERROR "expect APPLE platform")
endif()
message(STATUS "using Apple: ${CMAKE_OSX_SYSROOT}")

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
    message(FATAL_ERROR "requires CMAKE_INSTALL_PREFIX")
endif()

add_executable(damn_app
    main.mm
    interface.h
    native.cpp
    camera.mm
    metal.mm
    opengl.mm
)

set_target_properties(damn_app
PROPERTIES
    OBJCXX_STANDARD 17
    MACOSX_BUNDLE   true
    # XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
)

target_include_directories(damn_app
PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_INSTALL_PREFIX}/include
)

target_link_directories(damn_app
PRIVATE
    ${CMAKE_INSTALL_PREFIX}/lib
)

target_link_libraries(damn_app
PRIVATE
    ${CMAKE_DL_LIBS}
    "-framework CoreMedia" "-framework CoreVideo" "-framework AVFoundation"
    "-framework MetalKit" "-framework Metal"
)
if(CMAKE_SYSTEM MATCHES iOS)
    set_target_properties(damn_app
    PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST    ${CMAKE_CURRENT_SOURCE_DIR}/Info-iphone.plist
    )
    target_link_libraries(damn_app
    PRIVATE
        "-framework UIKit"
    )
else()
    set_target_properties(damn_app
    PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST    ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
    )
    target_link_libraries(damn_app
    PRIVATE
        "-framework AppKit" "-framework OpenGL"
    )
endif()

target_compile_options(damn_app
PRIVATE
    -Wall -Wextra
    -std=c++2a -stdlib=libc++
)

target_compile_definitions(damn_app
PRIVATE
    GL_SILENCE_DEPRECATION
)

include(BundleUtilities)

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

# xctest_add_bundle
xctest_add_bundle(test_suite
    damn_app
    Info.plist
    ${src}
)

set_target_properties(test_suite
PROPERTIES
    OBJCXX_STANDARD 17
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
    # XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
)

target_include_directories(test_suite
PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_INSTALL_PREFIX}/include
)

target_link_directories(test_suite
PRIVATE
    ${CMAKE_INSTALL_PREFIX}/lib
)

target_link_libraries(test_suite
PRIVATE
    ${CMAKE_DL_LIBS}
    "-framework CoreMedia"
)

target_compile_options(test_suite
PRIVATE
    -Wall -Wextra
    -std=c++2a -stdlib=libc++
)
