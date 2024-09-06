{
  coreutils,
  rsync,
  writeShellScriptBin,
  lib,
}:
flake:
let
  installScript = writeShellScriptBin "install.sh" ''
    ${coreutils}/bin/mkdir -p wasm_build
    ${rsync}/bin/rsync --chmod=u+w -r ${flake.packages.default}/* wasm_build/
  '';
in
lib.recursiveUpdate flake {
  apps.install = {
    type = "app";
    program = "${installScript}/bin/install.sh";
  };
}
