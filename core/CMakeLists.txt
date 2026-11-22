cmake_minimum_required(VERSION 3.21)

project(sparkmusic-core-qt
    VERSION 0.1.2
    DESCRIPTION "Qt-facing shared library built from the SparkMusic Rust core"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core)

# The Rust half is built by cargo. CMake links its static archive wholesale into
# a C++ shared object so the cxx-qt QObject symbols are exported; consumers
# (gui/) then link `libsparkmusic_core.so` dynamically.
find_program(CARGO_EXECUTABLE cargo REQUIRED)

if (TARGET Qt6::qmake)
    get_target_property(QMAKE_EXE Qt6::qmake IMPORTED_LOCATION)
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
    COMMAND ${CARGO_ENV} ${CARGO_EXECUTABLE} build --manifest-path "${CMAKE_CURRENT_SOURCE_DIR}/Cargo.toml"
    BYPRODUCTS "${CMAKE_CURRENT_SOURCE_DIR}/target/debug/libsparkmusic_core.a"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "cargo build sparkmusic-core"
    USES_TERMINAL)

add_library(sparkmusic_core SHARED qt_stub.cpp)
add_dependencies(sparkmusic_core sparkmusic_core_rust)

set_target_properties(sparkmusic_core PROPERTIES
    OUTPUT_NAME sparkmusic_core
    VERSION ${PROJECT_VERSION}
    SOVERSION 0)

target_include_directories(sparkmusic_core PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/target/cxxqt/include")

target_link_libraries(sparkmusic_core
    PUBLIC Qt6::Core
    PRIVATE "-Wl,--whole-archive" "${CMAKE_CURRENT_SOURCE_DIR}/target/debug/libsparkmusic_core.a"
            "-Wl,--no-whole-archive" pthread dl m)

install(TARGETS sparkmusic_core
    LIBRARY DESTINATION lib
    COMPONENT runtime)
