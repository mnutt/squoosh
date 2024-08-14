{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    fenix.url = "github:nix-community/fenix";
  };
  outputs =
    {
      self,
      nixpkgs,
      fenix,
    }:
    {
      lib = {
        buildRustPackage =
          {
            system,
            target,
            src,
            cargoLock ? {
              lockFile = "${src}/Cargo.lock";
            },
            release ? true,
            ...
          }@args:
          with nixpkgs.legacyPackages.${system};
          let
            # Setup a toolchain for the the host system targeting `target`.
            toolchain =
              with fenix.packages.${system};
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
                export CARGO_HOME=$TMPDIR/.cargo
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
      };
    };
}
