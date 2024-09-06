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
      fenix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) callPackage;

        buildSquooshRustCodec= callPackage (import ../../nix/squoosh-rust-builder) {fenix = fenix.packages.${system};};
        mkInstallable = callPackage (import ../../nix/mk-installable) {};

        src = ./.;
      in
      mkInstallable {
        packages = rec {
          default = resize-squoosh;
          resize-squoosh = buildSquooshRustCodec {
            name = "resize-squoosh";
            inherit src;
            cargoLock = {
              lockFile = "${src}/Cargo.lock";
            };
            wasmBindgen = {
              sha256 = "sha256-HTElSB76gqCpDu8S0ZJlfd/S4ftMrbwxFgJM9OXBRz8=";
            };
          };
        };
      }
    );
}
