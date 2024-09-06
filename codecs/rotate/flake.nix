
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
    fenix.url = "github:nix-community/fenix/7bad6c7ff73b784a9c7de9147626c8d5d5072809";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      fenix
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) callPackage writeShellScriptBin;
        
        buildSquooshRustCodec= callPackage (import ../../nix/squoosh-rust-builder) {fenix = fenix.packages.${system};};

        src = ./.;
      in
      {
        packages = rec {
          default = rotate-squoosh;
          rotate-squoosh = buildSquooshRustCodec {
            name = "rotate-squoosh";
            inherit src;
            cargoLock = {
              lockFile = "${src}/Cargo.lock";
            };
            wasmBindgen = null;
          };

          installScript = writeShellScriptBin "install.sh" ''
            ${pkgs.coreutils}/bin/mkdir -p wasm_build
            ${pkgs.rsync}/bin/rsync --chmod=u+w -r ${self.packages.${system}.rotate-squoosh}/* wasm_build/
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
