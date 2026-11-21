// Anchor translation unit for the shared SparkMusic core library.
// The actual symbols come from the Rust static archive, which the CMake target
// links with --whole-archive so the cxx-qt QObject classes stay exported.
namespace SparkMusic {
const char *coreLinkAnchor() { return "sparkmusic-core"; }
}
