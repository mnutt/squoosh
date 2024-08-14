{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    fenix.url = "github:nix-community/fenix";
    wasm-bindgen = {
      url = "path:../wasm-bindgen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-helpers = {
      url = "path:../rust-helpers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      fenix,
      wasm-bindgen,
      rust-helpers,
    }:
    {
      lib = {
        buildSquooshCodecRust =
          {
            name,
            system,
            src,
            cargoLock ? {
              lockFile = "${src}/Cargo.lock";
            },
            wasmBindgenSha,
            ...
          }@args:
          with nixpkgs.legacyPackages.${system};
          let
            wasm-bindgen-bin = wasm-bindgen.lib.buildFromCargoLock {
              inherit system cargoLock;
              sha256 = wasmBindgenSha;
            };

            codecBuild = rust-helpers.lib.buildRustPackage {
              inherit system src cargoLock;
              name = "${name}-codec";
              target = "wasm32-unknown-unknown";
            };
          in
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
          );
      };
    };
}
