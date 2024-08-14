{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
    fenix.url = "github:nix-community/fenix";
    wasm-bindgen = {
      url = "../../nix/wasm-bindgen";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      fenix,
      wasm-bindgen,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        target = "wasm32-unknown-unknown";
        pkgs = nixpkgs.legacyPackages.${system};
        toolchain =
          with fenix.packages.${system};
          combine [
            stable.rustc
            stable.cargo
            targets.${target}.stable.rust-std
          ];
        src = ./.;

        rustPlatform = pkgs.makeRustPlatform {
          cargo = toolchain;
          rustc = toolchain;
        };

        cargoLockFile = "${src}/Cargo.lock";

        vendor = rustPlatform.importCargoLock {
          lockFile = cargoLockFile;
        };

        wasm-bindgen-bin = wasm-bindgen.lib.buildFromCargoLock {
          inherit system cargoLockFile;
          sha256 = "sha256-HTElSB76gqCpDu8S0ZJlfd/S4ftMrbwxFgJM9OXBRz8=";
        };
      in
      with pkgs;
      {
        packages = rec {
          default = resize-squoosh;
          resize-squoosh = stdenv.mkDerivation {
            name = "squoosh-resize";
            inherit src;
            nativeBuildInputs = [
              toolchain
              wasm-bindgen-bin
            ];
            dontConfigure = true;
            buildPhase = ''
              runHook preBuild
              export CARGO_HOME=$TMPDIR/.cargo
              cargo build \
                --config 'source.crates-io.replace-with="vendored-sources"' \
                --config 'source.vendored-sources.directory="${vendor}"' \
                --offline \
                --target ${target} -r
              wasm-bindgen --target web --out-dir $out ./target/wasm32-unknown-unknown/release/*.wasm
              runHook postBuild
            '';
            dontInstall = true;
          };

          installScript = writeShellScriptBin "install.sh" ''
            ${pkgs.coreutils}/bin/mkdir -p wasm_build
            ${pkgs.rsync}/bin/rsync --chmod=u+w -r ${self.packages.${system}.resize-squoosh}/* wasm_build/
          '';
        };
        apps = {
          install = {
            type = "app";
            program = "${self.packages.${system}.installScript}/bin/install.sh";
          };
        };
      }
    );
}
