use std::path::{Path, PathBuf};

fn main() {
    cxx_qt_build::CxxQtBuilder::new()
        .qt_module("Core")
        .file("src/lib.rs")
        .build();

    // cxx-qt writes the generated headers under a hashed OUT_DIR.  Copy them
    // to `target/cxxqt/include` so C++/CMake consumers have a stable path.
    let out_dir = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR is set by cargo"));
    let generated = out_dir.join("cxxqtbuild").join("include");
    let manifest = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").expect("manifest dir"));
    let stable = manifest.join("target").join("cxxqt").join("include");
    if generated.is_dir() {
        copy_dir(&generated, &stable).expect("copy generated headers");
    }

    println!("cargo:rerun-if-changed=assets/routes.json");
}

fn copy_dir(from: &Path, to: &Path) -> std::io::Result<()> {
    std::fs::create_dir_all(to)?;
    for entry in std::fs::read_dir(from)? {
        let entry = entry?;
        let target = to.join(entry.file_name());
        // Follow symlinks: std::fs::copy refuses a link to a directory.
        let meta = std::fs::metadata(entry.path())?;
        if meta.is_dir() {
            copy_dir(&entry.path(), &target)?;
        } else if meta.is_file() {
            std::fs::copy(entry.path(), &target)?;
        }
    }
    Ok(())
}
