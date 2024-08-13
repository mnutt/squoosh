{
  outputs =
    { self, nixpkgs }:
    {
      lib = {
        build =
          {
            system,
            version,
            sha256,
          }:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            wasm-bindgen-src = pkgs.fetchCrate {
              pname = "wasm-bindgen-cli";
              inherit version sha256;
            };
          in
          pkgs.rustPlatform.buildRustPackage {
            name = "wasm-bindgen-cli";
            buildInputs = [
              pkgs.curl
              pkgs.darwin.apple_sdk.frameworks.Security
            ];
            src = wasm-bindgen-src;
            cargoLock = {
              lockFile = "${wasm-bindgen-src}/Cargo.lock";
            };
            doCheck = false;
          };

        buildFromCargoLock =
          {
            system,
            cargoLockFile,
            sha256,
          }:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            cargoLock = pkgs.lib.importTOML cargoLockFile;
            wasm-bindgen-version =
              (pkgs.lib.lists.findFirst (x: x.name == "wasm-bindgen") null cargoLock.package).version;
          in
          self.lib.build {
            inherit system sha256;
            version = wasm-bindgen-version;
          };
      };
    };
}
