{
  rustPlatform,
  jq,
  rsync,
  stdenv,
  fenix,
}:
{
  buildRustPackage =
    {
      target,
      src,
      cargoLock ? {
        lockFile = "${src}/Cargo.lock";
      },
      release ? true,
      ...
    }@args:
    let
      # Setup a toolchain for the the host system targeting `target`.
      toolchain =
        let
          inherit (fenix) stable targets combine;
        in
        combine [
          stable.rustc
          stable.cargo
          targets.${target}.stable.rust-std
        ];

      # Create `vendor` folder with all dependencies.
      vendoredDependencies = rustPlatform.importCargoLock cargoLock;

      rustcTargetDir = "target/${target}/${if release then "release" else "debug"}";
    in
    stdenv.mkDerivation (
      (removeAttrs args [ "cargoLock" ])
      // {
        nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
          toolchain
          jq
          rsync
        ];
        dontConfigure = true;
        buildPhase = ''
          runHook preBuild

          cargo build \
            --config 'source.crates-io.replace-with="vendored-sources"' \
            --config 'source.vendored-sources.directory="${vendoredDependencies}"' \
            --offline \
            --target ${target} ${if release then "-r" else ""}

          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall;
          mkdir -p $out

          find ${rustcTargetDir} -type f -maxdepth 1 | \
            xargs -I ___X -n1 cp ___X $out

          runHook postInstall;
        '';
      }
    );
}
