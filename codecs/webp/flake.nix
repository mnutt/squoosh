{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
    webp-src = {
      url = "github:webmproject/libwebp/d2e245ea9e959a5a79e1db0ed2085206947e98f2";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      webp-src,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      with pkgs;
      rec {
        packages = rec {
          default = webp-squoosh;
          webp-squoosh = stdenv.mkDerivation {
            name = "mozjpeg-squoosh";
            # Only copy files that are actually relevant to avoid unnecessary
            # cache invalidations.
            src = runCommand "src" { } ''
              mkdir $out
              cp -r ${./.}/enc $out/
              cp -r ${./.}/dec $out/
              cp ${./.}/Makefile $out/
            '';
            nativeBuildInputs = [
              emscripten
              webp
            ];
            WEBP = webp;
            dontConfigure = true;
            buildPhase = ''
              export HOME=$TMPDIR
              emmake make -j$(nproc)
            '';
            installPhase = ''
              mkdir -p $out
              cp -r enc dec $out
            '';
          };
          webp = stdenv.mkDerivation {
            name = "webp";
            src = webp-src;
            nativeBuildInputs = [
              # autoconf
              # automake
              # libtool
              emscripten
              # pkg-config
              cmake
            ];
            configurePhase = ''
                # $HOME is required for Emscripten to work.
                # See: https://nixos.org/manual/nixpkgs/stable/#emscripten
              	export HOME=$TMPDIR
                mkdir -p $TMPDIR/build
                emcmake cmake \
                  -DCMAKE_INSTALL_PREFIX=$out \
              		-DCMAKE_DISABLE_FIND_PACKAGE_Threads=1 \
              		-DWEBP_BUILD_ANIM_UTILS=0 \
              		-DWEBP_BUILD_CWEBP=0 \
              		-DWEBP_BUILD_DWEBP=0 \
              		-DWEBP_BUILD_GIF2WEBP=0 \
              		-DWEBP_BUILD_IMG2WEBP=0 \
              		-DWEBP_BUILD_VWEBP=0 \
              		-DWEBP_BUILD_WEBPINFO=0 \
              		-DWEBP_BUILD_WEBPMUX=0 \
              		-DWEBP_BUILD_EXTRAS=0 \
              		-B $TMPDIR/build \
                  .
            '';
            buildPhase = ''
              export HOME=$TMPDIR
              cd $TMPDIR/build
              emmake make V=1 -j$(nproc) --trace 
            '';
            installPhase = ''
              cd $TMPDIR/build
              make install
            '';
            dontFixup = true;
          };
          installScript = writeShellScriptBin "install.sh" ''
            ${pkgs.coreutils}/bin/rm -rf wasm_build
            ${pkgs.coreutils}/bin/mkdir -p wasm_build
            ${pkgs.rsync}/bin/rsync --chmod=u+w -r ${webp-squoosh}/* wasm_build/
          '';
        };
        apps = {
          install = {
            type = "app";
            program = "${packages.installScript}/bin/install.sh";
          };
        };
      }
    );
}
