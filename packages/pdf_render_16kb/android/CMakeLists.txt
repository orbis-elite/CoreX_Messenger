cmake_minimum_required(VERSION 3.4.1)

add_library(bbhelper SHARED c++/directBufferAndroid.cpp)

target_compile_options(bbhelper PRIVATE -DBUILD_FOR_ANDROID)

# Android 15+ devices may use 16 KB memory pages. Align every LOAD segment so
# this native helper can be loaded on both 4 KB and 16 KB page-size devices.
target_link_options(bbhelper PRIVATE "-Wl,-z,max-page-size=16384")
