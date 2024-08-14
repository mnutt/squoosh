{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
    wasm-bindgen = {
      url = "../../nix/wasm-bindgen";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    rust-helpers = {
      url = "../../nix/rust-helpers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    squoosh-codec-builders = {
      url = "../../nix/squoosh-codec-builders";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-helpers.follows = "rust-helpers";
      inputs.wasm-bindgen.follows = "wasm-bindgen";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      squoosh-codec-builders,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      with nixpkgs.legacyPackages.${system};
      let
        src = ./.;
      in
      # wasm-bindgen-bin = wasm-bindgen.lib.buildFromCargoLock {
      #   inherit system cargoLock;
      #   sha256 = "sha256-HTElSB76gqCpDu8S0ZJlfd/S4ftMrbwxFgJM9OXBRz8=";
      # };
      {
        packages = rec {
          default = resize-squoosh;
          resize-squoosh = squoosh-codec-builders.lib.buildSquooshCodecRust {
            name = "resize-squoosh";
            inherit system src;
            cargoLock = {
              lockFile = "${src}/Cargo.lock";
            };
          };
          # resize-squoosh = stdenv.mkDerivation {
          #   name = "squoosh-resize";
          #   inherit src;
          #   nativeBuildInputs = [
          #     toolchain
          #     wasm-bindgen-bin
          #   ];
          #   dontConfigure = true;
          #   buildPhase = ''
          #     runHook preBuild
          #     export CARGO_HOME=$TMPDIR/.cargo
          #     cargo build \
          #       --config 'source.crates-io.replace-with="vendored-sources"' \
          #       --config 'source.vendored-sources.directory="${vendoredDependencies}"' \
          #       --offline \
          #       --target ${target} -r
          #     wasm-bindgen --target web --out-dir $out ./target/wasm32-unknown-unknown/release/*.wasm
          #     runHook postBuild
          #   '';
          #   dontInstall = true;
          # };

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
