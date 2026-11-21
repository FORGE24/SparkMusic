cmake_minimum_required(VERSION 3.21)

project(sparkmusic-gui LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia)
qt_standard_project_setup()

# core/ builds `libsparkmusic_core.so` (cargo + the cxx-qt glue); this shell
# links it dynamically and only owns the QML/UI side.
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../core"
                 "${CMAKE_CURRENT_BINARY_DIR}/core")

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

# Brand assets are embedded, so the app icon, top-bar mark and login wordmark
# work from the executable without extra files on disk.
qt_add_resources(sparkmusic "branding"
    PREFIX "/branding"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/../branding"
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/../branding/icon-paper.png"
        "${CMAKE_CURRENT_SOURCE_DIR}/../branding/mark-paper.png"
        "${CMAKE_CURRENT_SOURCE_DIR}/../branding/mark-ink.png"
        "${CMAKE_CURRENT_SOURCE_DIR}/../branding/wordmark.png"
        "${CMAKE_CURRENT_SOURCE_DIR}/../branding/wordmark-ink.png")
