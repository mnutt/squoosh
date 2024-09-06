{
  fenix,
  wasm-bindgen,
  rust-helpers,
  stdenv,
}:
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
      codecBuild = rust-helpers.lib.buildRustPackage {
        inherit src cargoLock;
        name = "${name}-codec";
        target = "wasm32-unknown-unknown";
      };

      wasm-bindgen-bin = wasm-bindgen.lib.buildFromCargoLock {
        inherit cargoLock;
        sha256 = wasmBindgen.sha256;
      };
    in
    if wasmBindgen != null then
      stdenv.mkDerivation (
        (removeAttrs args [ "cargoLock" ])
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
