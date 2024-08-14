{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
    wasm-bindgen = {
      url = "path:../../nix/wasm-bindgen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-helpers = {
      url = "path:../../nix/rust-helpers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    squoosh-codec-builders = {
      url = "path:../../nix/squoosh-codec-builders";
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
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      with nixpkgs.legacyPackages.${system};
      let
        src = ./.;
      in
      {
        packages = rec {
          default = resize-squoosh;
          resize-squoosh = squoosh-codec-builders.lib.buildSquooshCodecRust {
            name = "resize-squoosh";
            inherit system src;
            cargoLock = {
              lockFile = "${src}/Cargo.lock";
            };
            wasmBindgenSha = "sha256-HTElSB76gqCpDu8S0ZJlfd/S4ftMrbwxFgJM9OXBRz8=";
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
