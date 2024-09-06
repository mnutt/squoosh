{
  pkgs,
  fenix,
  wasm-bindgen ? pkgs.callPackage (import ../wasm-bindgen) { },
  rust-helpers ? pkgs.callPackage (import ../rust-helpers) { inherit fenix; },
  binaryen,
  stdenv,
}:
let
  inherit (rust-helpers) buildRustPackage;
in

{
  name,
  src,
  cargoLock ? {
    lockFile = "${src}/Cargo.lock";
  },
  wasmBindgen ? {
    sha256 = "";
  },
  ...
}@args:
let
  codecBuild = buildRustPackage {
    inherit src cargoLock;
    name = "${name}-codec";
    target = "wasm32-unknown-unknown";
  };

  wasm-bindgen-bin = wasm-bindgen.buildFromCargoLock {
    inherit cargoLock;
    sha256 = wasmBindgen.sha256;
  };
in
if wasmBindgen != null then
  stdenv.mkDerivation (
    (removeAttrs args [
      "cargoLock"
      "wasmBindgen"
    ])
    // {
      inherit codecBuild;
      dontConfigure = true;
      nativeBuildInputs = [ wasm-bindgen-bin ];
      buildPhase = ''
        runHook preBuild

        wasm-bindgen --target web --out-dir $out $codecBuild/*.wasm

        runHook postBuild
      '';
      dontInstall = true;
    }
  )
else
  stdenv.mkDerivation (
    (removeAttrs args [
      "cargoLock"
      "wasmBindgen"
    ])
    // {
      inherit codecBuild;
      dontConfigure = true;
      nativeBuildInputs = [ binaryen ];
      buildPhase = ''
        runHook preBuild

        wasm-opt -O3 --strip -o optimized.wasm $codecBuild/*.wasm

        runHook postBuild
      '';
      installPhase = ''
        mkdir -p $out
        cp optimized.wasm $out
      '';
    }
  )
