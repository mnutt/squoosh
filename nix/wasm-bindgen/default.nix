{
  lib,
  fetchCrate,
  rustPlatform,
  curl,
  darwin,
}:
rec {
  build =
    { version, sha256 }:
    let
      src = fetchCrate {
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
    build {
      inherit system sha256;
      version = wasm-bindgen-version;
    };
}
