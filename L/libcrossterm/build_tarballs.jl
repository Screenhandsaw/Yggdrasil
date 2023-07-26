# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libcrossterm"
version = v"0.6.1"

sources = [
  GitSource(
    "https://github.com/kdheepak/libcrossterm.git",
    "341a1c01878a321a4479283e96e4c501fe8b98ea"
  )
]

script = raw"""
cd $WORKSPACE/srcdir/libcrossterm/

cargo build --release -j${nproc} --target=${rust_target}

if [[ "${target}" == *-w64-mingw32* ]]; then
    # Windows generates .dlls without the lib prefix
    install -Dvm 0755 "target/${rust_target}/release/crossterm.${dlext}" "${libdir}/libcrossterm.${dlext}"
else
    install -Dvm 0755 "target/${rust_target}/release/libcrossterm.${dlext}" "${libdir}/libcrossterm.${dlext}"
fi

install -Dvm 0755 "include/crossterm.h" "${includedir}/crossterm.h"

install_license LICENSE
"""

platforms = supported_platforms()
# `cdylib` apparently doesn't support musl
filter!(p -> libc(p) != "musl", platforms)
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

products = [
  LibraryProduct("libcrossterm", :libcrossterm),
  FileProduct("include/crossterm.h", :crossterm_h),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")