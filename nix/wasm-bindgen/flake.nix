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
          with nixpkgs.legacyPackages.${system};
          let
            src = pkgs.fetchCrate {
              pname = "wasm-bindgen-cli";
              inherit version sha256;
            };

            cargoLock = {
              lockFile = "${src}/Cargo.lock";
            };
          in
          rustPlatform.buildRustPackage {
            name = "wasm-bindgen-cli";
            inherit src cargoLock;
            buildInputs = [
              curl
              darwin.apple_sdk.frameworks.Security
            ];
            doCheck = false;
          };

        buildFromCargoLock =
          {
            system,
            cargoLock,
            sha256,
          }:
          with nixpkgs.legacyPackages.${system};
          assert (cargoLock.lockFile or null == null) != (cargoLock.lockFileContents or null == null);
          let
            lockFileContents =
              if cargoLock.lockFile != null then
                builtins.readFile cargoLock.lockFile
              else
                cargoLock.lockFileContents;

            parsedLockFile = builtins.fromTOML lockFileContents;

            wasm-bindgen-version =
              (lib.lists.findFirst (x: x.name == "wasm-bindgen") null parsedLockFile.package).version;
          in
          assert wasm-bindgen-version != null;
          self.lib.build {
            inherit system sha256;
            version = wasm-bindgen-version;
          };
      };
    };
}
