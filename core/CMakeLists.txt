cmake_minimum_required(VERSION 3.21)

project(sparkmusic-core-qt
    VERSION 0.1.3
    DESCRIPTION "Qt-facing shared library built from the SparkMusic Rust core"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core)

# Relative library directory under the install prefix. Defaults to "lib" for
# the portable/DEB layouts; RPM builds pass -DSPARKMUSIC_LIBDIR=%{_lib} so the
# core lands in /usr/lib64.
set(SPARKMUSIC_LIBDIR "lib" CACHE STRING "Library install directory (relative)")

# Cargo profile for the Rust half. Release packaging passes `release`; the
# default stays `debug` so existing developer builds and tests keep using the
# already-warm debug cache.
set(SPARKMUSIC_CARGO_PROFILE "debug" CACHE STRING "Cargo profile for the Rust core (debug or release)")
set_property(CACHE SPARKMUSIC_CARGO_PROFILE PROPERTY STRINGS debug release)
if (NOT SPARKMUSIC_CARGO_PROFILE MATCHES "^(debug|release)$")
    message(FATAL_ERROR "SPARKMUSIC_CARGO_PROFILE must be 'debug' or 'release', got '${SPARKMUSIC_CARGO_PROFILE}'")
endif()

# The Rust half is built by cargo. CMake links its static archive wholesale into
# a C++ shared object; consumers then link the shared object dynamically.
find_program(CARGO_EXECUTABLE cargo REQUIRED)

if (TARGET Qt6::qmake)
    get_target_property(QMAKE_EXE Qt6::qmake IMPORTED_LOCATION)
endif()

set(CARGO_PROFILE_ARGS)
if (SPARKMUSIC_CARGO_PROFILE STREQUAL "release")
    list(APPEND CARGO_PROFILE_ARGS --release)
endif()

set(RUST_TARGET_DIR "${CMAKE_CURRENT_SOURCE_DIR}/target/${SPARKMUSIC_CARGO_PROFILE}")
if (MSVC)
    # MSVC's Rust target emits sparkmusic_core.lib, unlike libsparkmusic_core.a
    # on Unix/MinGW.
    set(RUST_STATIC_LIB "${RUST_TARGET_DIR}/sparkmusic_core.lib")
else()
    set(RUST_STATIC_LIB "${RUST_TARGET_DIR}/libsparkmusic_core.a")
endif()

# Keep CARGO_HOME untouched when the caller provides one (CI caches it there);
# only fall back to the in-repo cache used on this read-only-home build host.
set(CARGO_ENV ${CMAKE_COMMAND} -E env "CCACHE_DISABLE=1")
if (DEFINED ENV{CARGO_HOME} AND NOT "$ENV{CARGO_HOME}" STREQUAL "")
    list(APPEND CARGO_ENV "CARGO_HOME=$ENV{CARGO_HOME}")
elseif (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.cargo-home")
    list(APPEND CARGO_ENV "CARGO_HOME=${CMAKE_CURRENT_SOURCE_DIR}/.cargo-home")
endif()
if (QMAKE_EXE)
    list(APPEND CARGO_ENV "QMAKE=${QMAKE_EXE}")
endif()

add_custom_target(sparkmusic_core_rust ALL
    COMMAND ${CARGO_ENV} ${CARGO_EXECUTABLE} build
            --manifest-path "${CMAKE_CURRENT_SOURCE_DIR}/Cargo.toml"
            ${CARGO_PROFILE_ARGS}
    BYPRODUCTS "${RUST_STATIC_LIB}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "cargo build sparkmusic-core (${SPARKMUSIC_CARGO_PROFILE})"
    USES_TERMINAL)

add_library(sparkmusic_core SHARED qt_stub.cpp c_api.cpp)
add_dependencies(sparkmusic_core sparkmusic_core_rust)

# The C API is the only surface consumers import: see
# include/sparkmusic/core_api.h.  This keeps the DLL ABI independent of CXX-Qt's
# generated class (which has no dllimport annotations).
target_compile_definitions(sparkmusic_core PRIVATE SPARKMUSIC_CORE_BUILD)

set_target_properties(sparkmusic_core PROPERTIES
    OUTPUT_NAME sparkmusic_core
    VERSION ${PROJECT_VERSION}
    SOVERSION 0)

target_include_directories(sparkmusic_core PUBLIC
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
    "${CMAKE_CURRENT_SOURCE_DIR}/target/cxxqt/include")

target_link_libraries(sparkmusic_core PUBLIC Qt6::Core)

if (MSVC)
    # /WHOLEARCHIVE makes cargo's object files part of the DLL even though the
    # C++ side only references the factory in c_api.cpp.
    target_link_libraries(sparkmusic_core PRIVATE
        "/WHOLEARCHIVE:${RUST_STATIC_LIB}"
        ws2_32 userenv bcrypt advapi32 ole32 shell32)
elseif (WIN32)
    target_link_libraries(sparkmusic_core PRIVATE
        "-Wl,--whole-archive" "${RUST_STATIC_LIB}" "-Wl,--no-whole-archive"
        ws2_32 userenv bcrypt advapi32 ole32 shell32)
else()
    target_link_libraries(sparkmusic_core PRIVATE
        "-Wl,--whole-archive" "${RUST_STATIC_LIB}" "-Wl,--no-whole-archive"
        pthread dl m)
endif()

if (WIN32)
    install(TARGETS sparkmusic_core RUNTIME DESTINATION . COMPONENT runtime)
else()
    install(TARGETS sparkmusic_core
        LIBRARY DESTINATION ${SPARKMUSIC_LIBDIR}
        COMPONENT runtime)
endif()
