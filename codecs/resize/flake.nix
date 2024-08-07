{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
    fenix.url = "github:nix-community/fenix";
    naersk.url = "github:nix-community/naersk";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      fenix,
      naersk,
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
        naersk' = pkgs.callPackage naersk {
          rustc = toolchain;
          cargo = toolchain;
        };
      in
      with pkgs;
      {
        packages = rec {
          default = resize-squoosh;
          resize-squoosh = stdenv.mkDerivation {
            name = "squoosh-resize";
            src = ./.;
            nativeBuildInputs = [
              #naersk'
              toolchain
              # wasm-pack
              wasm-bindgen-cli
            ];
            dontConfigure = true;
            buildPhase = ''
              export CARGO_HOME=$TMPDIR/.cargo
              cargo build --target wasm32-unknown-unknown -r
              wasm-bindgen --target web --out-dir $out ./target/wasm32-unknown-unknown/release/*.wasm
            '';
            dontInstall = true;
            # installPhase = ''
            #   mkdir -p $out
            #   cp -r pkg/* $out
            # '';
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
