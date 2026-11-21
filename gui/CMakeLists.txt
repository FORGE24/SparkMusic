cmake_minimum_required(VERSION 3.21)
project(sparkmusic-gui LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia)
qt_standard_project_setup()

set(CORE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")

# The Rust core is built by cargo; CMake only consumes its static library and
# the generated cxx-qt headers.
find_program(CARGO_EXECUTABLE cargo REQUIRED)

if (TARGET Qt6::qmake)
    get_target_property(QMAKE_EXE Qt6::qmake IMPORTED_LOCATION)
endif()

set(CARGO_ENV ${CMAKE_COMMAND} -E env
    "CARGO_HOME=${CORE_ROOT}/.cargo-home"
    "CCACHE_DISABLE=1")
if (QMAKE_EXE)
    list(APPEND CARGO_ENV "QMAKE=${QMAKE_EXE}")
endif()

add_custom_target(sparkmusic_core_rust ALL
    COMMAND ${CARGO_ENV} ${CARGO_EXECUTABLE} build --manifest-path "${CORE_ROOT}/Cargo.toml"
    BYPRODUCTS "${CORE_ROOT}/target/debug/libsparkmusic_core.a"
    WORKING_DIRECTORY "${CORE_ROOT}"
    COMMENT "cargo build sparkmusic-core"
    USES_TERMINAL)

# Shared core library: the Rust static archive is linked wholesale into a C++
# shared object, so the cxx-qt QObject symbols are exported and the GUI can
# link it dynamically (swap the .so to change the API implementation).
add_library(sparkmusic_core SHARED core_stub.cpp)
add_dependencies(sparkmusic_core sparkmusic_core_rust)
set_target_properties(sparkmusic_core PROPERTIES
    OUTPUT_NAME sparkmusic_core
    VERSION 0.1.0
    SOVERSION 0)
target_include_directories(sparkmusic_core PUBLIC
    "${CORE_ROOT}/target/cxxqt/include")
target_link_libraries(sparkmusic_core
    PUBLIC Qt6::Core
    PRIVATE "-Wl,--whole-archive" "${CORE_ROOT}/target/debug/libsparkmusic_core.a"
            "-Wl,--no-whole-archive" pthread dl m)

qt_add_executable(sparkmusic main.cpp)

add_dependencies(sparkmusic sparkmusic_core)

target_link_libraries(sparkmusic PRIVATE
    sparkmusic_core
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Multimedia
    pthread dl m)

set_target_properties(sparkmusic PROPERTIES
    BUILD_RPATH "$ORIGIN"
    INSTALL_RPATH "$ORIGIN/../lib")

qt_add_qml_module(sparkmusic
    URI SparkMusic
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/LoginView.qml
        qml/HomeView.qml
        qml/PlayerView.qml
        qml/LyricLine.qml
        qml/SwissButton.qml
        qml/TrackRow.qml)
