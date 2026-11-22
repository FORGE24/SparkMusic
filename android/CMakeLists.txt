cmake_minimum_required(VERSION 3.22)

project(SparkMusicAndroid VERSION 0.4.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Gui Multimedia Concurrent)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(sparkmusic
    main.cpp
    CoreAsync.cpp
    CoreAsync.h
)

qt_add_qml_module(sparkmusic
    URI SparkMusicAndroid
    VERSION 1.0
    QML_FILES
        Main.qml
        components/StilleTextButton.qml
        components/StampArt.qml
        components/GridOverlay.qml
        components/GrainOverlay.qml
        components/Horizon.qml
        components/TrackRow.qml
        components/PlayerView.qml
        components/HomeView.qml
        components/LoginView.qml
        components/AuthView.qml
        components/LandscapeView.qml
        components/PlaylistPage.qml
        components/MiniPlayer.qml
        components/StilleMark.qml
        components/LogoLockup.qml
)

qt_add_resources(sparkmusic "app_fonts"
    PREFIX "/fonts"
    BASE "fonts"
    FILES
        fonts/CormorantGaramond-Regular.ttf
        fonts/CormorantGaramond-SemiBold.ttf
        fonts/STILLE-Song.ttf
)

qt_add_resources(sparkmusic "branding"
    PREFIX "/branding"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/branding"
    FILES
        branding/stille-wordmark-paper.png
        branding/stille-wordmark-ink.png
        branding/stille-lockup-paper.png
        branding/stille-lockup-ink.png
        branding/stille-seal-paper.png
        branding/stille-seal-ink.png
        branding/stille-icon-512.png
)

set(SPARKMUSIC_CORE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../core")
set(SPARKMUSIC_CORE_ARCHIVE "${SPARKMUSIC_CORE_DIR}/target/aarch64-linux-android/release/libsparkmusic_core.a")
option(SPARKMUSIC_USE_PREBUILT_CORE "Desktop preview: link the existing host libsparkmusic_core instead of rebuilding Cargo" OFF)

if(ANDROID)
    if(NOT EXISTS "${SPARKMUSIC_CORE_ARCHIVE}")
        message(FATAL_ERROR "Android Rust core archive missing: ${SPARKMUSIC_CORE_ARCHIVE}. Run scripts/build-core-android.sh first.")
    endif()
    target_include_directories(sparkmusic PRIVATE "${SPARKMUSIC_CORE_DIR}/target/cxxqt/include")
target_link_libraries(sparkmusic PRIVATE
        "-Wl,--whole-archive" "${SPARKMUSIC_CORE_ARCHIVE}" "-Wl,--no-whole-archive"
        Qt6::Quick Qt6::Gui Qt6::Multimedia Qt6::Concurrent
        log android)
elseif(SPARKMUSIC_USE_PREBUILT_CORE)
    set(SPARKMUSIC_HOST_CORE "${SPARKMUSIC_CORE_DIR}/build/libsparkmusic_core.so.0.1.0")
    if(NOT EXISTS "${SPARKMUSIC_HOST_CORE}")
        message(FATAL_ERROR "Host core not built: ${SPARKMUSIC_HOST_CORE}")
    endif()
    target_include_directories(sparkmusic PRIVATE "${SPARKMUSIC_CORE_DIR}/target/cxxqt/include")
    target_link_libraries(sparkmusic PRIVATE
        "${SPARKMUSIC_HOST_CORE}"
        Qt6::Quick Qt6::Gui Qt6::Multimedia Qt6::Concurrent
        pthread dl m)
    set_target_properties(sparkmusic PROPERTIES BUILD_RPATH "${SPARKMUSIC_CORE_DIR}/build")
else()
    add_subdirectory("${SPARKMUSIC_CORE_DIR}" "${CMAKE_BINARY_DIR}/core")
    target_include_directories(sparkmusic PRIVATE "${SPARKMUSIC_CORE_DIR}/target/cxxqt/include")
    add_dependencies(sparkmusic sparkmusic_core)
    target_link_libraries(sparkmusic PRIVATE
        sparkmusic_core
        Qt6::Quick Qt6::Gui Qt6::Multimedia Qt6::Concurrent
        pthread dl m)
endif()

set_target_properties(sparkmusic PROPERTIES
    QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
    QT_ANDROID_APP_NAME "静听 · STILLE"
    QT_ANDROID_TARGET_SDK_VERSION 36
    QT_ANDROID_MIN_SDK_VERSION 28
    QT_ANDROID_VERSION_NAME "0.4.1"
    QT_ANDROID_VERSION_CODE 1
)

