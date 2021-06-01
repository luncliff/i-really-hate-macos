


## How To

### Setup

```
wget https://raw.githubusercontent.com/leetal/ios-cmake/4.2.0/ios.toolchain.cmake
```

### Build

```
export WORKSPACE=$(pwd)
mkdir -p build && pushd build
    cmake .. -G Xcode \
        -DCMAKE_TOOLCHAIN_FILE=${WORKSPACE}/ios.toolchain.cmake \
        -DPLATFORM=MAC -DDEPLOYMENT_TARGET=10.13 \
        -DBUILD_TESTING=true
popd
```

```
open ./build/hate_this.xcodeproj
```