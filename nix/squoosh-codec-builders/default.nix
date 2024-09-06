{
  pkgs,
  fenix,
  wasm-bindgen ? pkgs.callPackage (import ../wasm-bindgen) { },
  rust-helpers ? pkgs.callPackage (import ../rust-helpers) { inherit fenix; },
  stdenv,
}:
let
  inherit (rust-helpers) buildRustPackage;
in

{
  buildSquooshCodecRust =
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
          nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ wasm-bindgen-bin ];
          buildPhase = ''
            runHook preBuild

            wasm-bindgen --target web --out-dir $out $codecBuild/*.wasm

            runHook postBuild
          '';
          dontInstall = true;
        }
      )
    else
      codecBuild;
}
