cmake_minimum_required(VERSION 3.21)

project(sparkmusic-gui VERSION 0.1.3 LANGUAGES CXX)

if (WIN32)
    enable_language(RC)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(SPARKMUSIC_LIBDIR "lib" CACHE STRING "Library install directory (relative)")

# Display version baked into --version, the QML launch screen and the Windows
# resource block. Release automation passes the tag version, e.g. 0.1.4-beta.
set(SPARKMUSIC_VERSION "${PROJECT_VERSION}-beta" CACHE STRING "SparkMusic display version")

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia)
qt_standard_project_setup()

# core/ builds `libsparkmusic_core.so` (cargo + the cxx-qt glue); this shell
# links it dynamically and only owns the QML/UI side.
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../core"
                 "${CMAKE_CURRENT_BINARY_DIR}/core")

# WIN32 turns this into a GUI-subsystem executable on Windows (no console
# window); it is ignored on other platforms.
qt_add_executable(sparkmusic WIN32 main.cpp)
target_compile_definitions(sparkmusic PRIVATE
    SPARKMUSIC_VERSION="${SPARKMUSIC_VERSION}")
add_dependencies(sparkmusic sparkmusic_core)

target_link_libraries(sparkmusic PRIVATE
    sparkmusic_core
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Multimedia)

if (UNIX)
    target_link_libraries(sparkmusic PRIVATE pthread dl m)
endif()

set_target_properties(sparkmusic PROPERTIES
    BUILD_RPATH "$ORIGIN"
    INSTALL_RPATH "$ORIGIN/../${SPARKMUSIC_LIBDIR}")

if (WIN32)
    # VERSIONINFO + application icon. FileVersion must be numeric, so the
    # `-beta` suffix only goes into the string fields.
    if (SPARKMUSIC_VERSION MATCHES "^([0-9]+)\\.([0-9]+)\\.([0-9]+)")
        set(SPARKMUSIC_VERSION_RC "${CMAKE_MATCH_1},${CMAKE_MATCH_2},${CMAKE_MATCH_3},0")
    else()
        set(SPARKMUSIC_VERSION_RC "0,1,3,0")
    endif()
    file(TO_NATIVE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/sparkmusic.ico" SPARKMUSIC_ICON_RC)
    configure_file(sparkmusic.rc.in
                   "${CMAKE_CURRENT_BINARY_DIR}/sparkmusic.rc" @ONLY)
    target_sources(sparkmusic PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/sparkmusic.rc")

    # Make the build-tree executable runnable: the core DLL is built in
    # build/core/ but Windows searches the executable's own directory first.
    add_custom_command(TARGET sparkmusic POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "$<TARGET_FILE:sparkmusic_core>"
                "$<TARGET_FILE_DIR:sparkmusic>"
        COMMENT "Copy sparkmusic_core.dll next to sparkmusic.exe"
        VERBATIM)
endif()

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
qt_add_resources(sparkmusic "fonts"
    PREFIX "/fonts"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/fonts"
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/fonts/CormorantGaramond-Regular.ttf"
        "${CMAKE_CURRENT_SOURCE_DIR}/fonts/CormorantGaramond-SemiBold.ttf")

qt_add_resources(sparkmusic "branding"
    PREFIX "/branding"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/../branding"
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/../branding/icon-paper.png"
        "${CMAKE_CURRENT_SOURCE_DIR}/../branding/mark-paper.png"
        "${CMAKE_CURRENT_SOURCE_DIR}/../branding/mark-ink.png"
        "${CMAKE_CURRENT_SOURCE_DIR}/../branding/wordmark.png"
        "${CMAKE_CURRENT_SOURCE_DIR}/../branding/wordmark-ink.png")

# ---- install layout ----
if (WIN32)
    # Portable Windows layout: executable, core DLL and notices all in one
    # directory. packaging/windows/package.ps1 installs here, then adds the Qt
    # DLLs with windeployqt.
    install(TARGETS sparkmusic RUNTIME DESTINATION . COMPONENT runtime)
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../LICENSE"
                  "${CMAKE_CURRENT_SOURCE_DIR}/../NOTICE"
                  "${CMAKE_CURRENT_SOURCE_DIR}/../THIRD_PARTY.md"
            DESTINATION . COMPONENT doc)
else()
    # Linux/nfpm layout (see packaging/).
    install(TARGETS sparkmusic RUNTIME DESTINATION bin COMPONENT runtime)
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/sparkmusic.desktop"
            DESTINATION share/applications COMPONENT runtime)
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../branding/icon-paper.png"
            DESTINATION share/icons/hicolor/512x512/apps
            RENAME sparkmusic.png COMPONENT runtime)
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../LICENSE"
                  "${CMAKE_CURRENT_SOURCE_DIR}/../NOTICE"
            DESTINATION share/doc/sparkmusic COMPONENT doc)
endif()
