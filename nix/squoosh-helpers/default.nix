{
  coreutils,
  rsync,
  writeShellScriptBin,
  lib,
}:
let
  suffixAttrNames =
    suffix: attrs: lib.mapAttrs' (name: val: lib.nameValuePair "${name}${suffix}" val) attrs;
in
{
  inherit suffixAttrNames;

  mkInstallable =
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
    };

  forAllVariants =
    { builder, variants }:
    lib.lists.foldl (acc: v: acc // v) { } (
      lib.mapAttrsToList (
        variantName: value: suffixAttrNames "-${variantName}" (builder variantName value)
      ) variants
    );
}
