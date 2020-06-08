cmake_minimum_required(VERSION 3.8)
project(camera_macosx LANGUAGES CXX OBJCXX)

if(NOT APPLE)
    message(FATAL_ERROR "expect APPLE platform")
endif()
message(STATUS "using Apple: ${CMAKE_OSX_SYSROOT}")

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
    message(FATAL_ERROR "requires CMAKE_INSTALL_PREFIX")
endif()

include(ExternalProject)
ExternalProject_Add(external_zlib
    TMP_DIR             ${CMAKE_BINARY_DIR}/download
    DOWNLOAD_DIR        ${CMAKE_CURRENT_SOURCE_DIR}/externals
    SOURCE_DIR          ${CMAKE_CURRENT_SOURCE_DIR}/externals/zlib
    GIT_REPOSITORY      https://github.com/madler/zlib.git
    GIT_TAG             v1.2.11
    GIT_SHALLOW         true
    BUILD_IN_SOURCE     true
    PATCH_COMMAND       git status
    CONFIGURE_COMMAND   cmake . -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
                                -DCMAKE_BUILD_TYPE=Debug
    BUILD_COMMAND       cmake --build . 
    BUILD_ALWAYS        true
    INSTALL_COMMAND     cmake --build . --target install
)
ExternalProject_Add(external_libpng
    DEPENDS     external_zlib
    TMP_DIR             ${CMAKE_BINARY_DIR}/download
    DOWNLOAD_DIR        ${CMAKE_CURRENT_SOURCE_DIR}/externals
    SOURCE_DIR          ${CMAKE_CURRENT_SOURCE_DIR}/externals/libpng
    GIT_REPOSITORY      https://github.com/glennrp/libpng.git
    GIT_TAG             v1.6.37
    GIT_SHALLOW         true
    BUILD_IN_SOURCE     true
    PATCH_COMMAND       git status
    CONFIGURE_COMMAND   cmake . -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
                                -DCMAKE_BUILD_TYPE=Debug
                                -DSKIP_INSTALL_PROGRAMS=ON
                                -DSKIP_INSTALL_EXECUTABLES=ON
                                -DSKIP_INSTALL_FILES=ON                        
    BUILD_COMMAND       cmake --build . 
    BUILD_ALWAYS        true
    INSTALL_COMMAND     cmake --build . --target install
)

add_executable(camera_app
    main.mm
    interface.h
    native.cpp
    camera.mm
    metal.mm
)
add_dependencies(camera_app     external_zlib 
                                external_libpng
)

set_target_properties(camera_app
PROPERTIES
    OBJCXX_STANDARD 17
    MACOSX_BUNDLE   true
    MACOSX_BUNDLE_INFO_PLIST    ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
)

target_include_directories(camera_app
PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_INSTALL_PREFIX}/include
)

target_link_directories(camera_app
PRIVATE
    ${CMAKE_INSTALL_PREFIX}/lib
)

target_link_libraries(camera_app
PRIVATE
    ${CMAKE_DL_LIBS}
    "-framework AppKit"
    "-framework CoreVideo" "-framework AVFoundation"
    "-framework MetalKit" "-framework Metal"
)

target_compile_options(camera_app
PRIVATE
    -Wall -Wextra
    -std=c++2a -stdlib=libc++
)

include(BundleUtilities)

install(TARGETS camera_app
        BUNDLE DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
)
