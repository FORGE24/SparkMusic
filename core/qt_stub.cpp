// Anchor translation unit for the shared SparkMusic core library.
// The actual symbols come from the Rust static archive, which CMake links with
// --whole-archive (/WHOLEARCHIVE on MSVC).  The exported surface is the small
// C API in c_api.cpp, so the CXX-Qt QObject does not need to be imported by the
// GUI on Windows.
namespace SparkMusic {
const char *coreLinkAnchor() { return "sparkmusic-core"; }
}
