cmake_minimum_required(VERSION 3.21)
project(sparkmusic_smoke LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core)

# Rust static library built by `cargo build` in the crate root.
set(CORE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../..")
set(CORE_LIB "${CORE_ROOT}/build/libsparkmusic_core.so")
if (NOT EXISTS "${CORE_LIB}")
    message(FATAL_ERROR
        "Build the core shared library first: cmake -S core -B core/build && cmake --build core/build")
endif()

add_executable(smoke smoke.cpp)
target_include_directories(smoke PRIVATE "${CORE_ROOT}/target/cxxqt/include")

# Link the shared library; Qt is a public dependency of it.
target_link_libraries(smoke PRIVATE
    "${CORE_LIB}"
    Qt6::Core
    pthread dl m)
