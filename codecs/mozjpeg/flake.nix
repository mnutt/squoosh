{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
    mozjpeg-src = {
      url = "github:mozilla/mozjpeg/v3.3.1";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      mozjpeg-src,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      with pkgs;
      rec {
        packages = rec {
          default = mozjpeg-squoosh;
          mozjpeg-squoosh = stdenv.mkDerivation {
            name = "mozjpeg-squoosh";
            # Only copy files that are actually relevant to avoid unnecessary
            # cache invalidations.
            src = runCommand "src" { } ''
              mkdir $out
              cp -r ${./.}/enc $out/
              cp ${./.}/Makefile $out/
            '';
            nativeBuildInputs = [
              emscripten
              mozjpeg
            ];
            MOZJPEG = mozjpeg;
            dontConfigure = true;
            buildPhase = ''
              export HOME=$TMPDIR
              emmake make -j$(nproc)
            '';
            installPhase = ''
              mkdir -p $out
              cp -r enc $out
            '';
          };
          mozjpeg = stdenv.mkDerivation {
            name = "mozjpeg";
            src = mozjpeg-src;
            nativeBuildInputs = [
              autoconf
              automake
              libtool
              emscripten
              pkg-config
            ];
            configurePhase = ''
                # $HOME is required for Emscripten to work.
                # See: https://nixos.org/manual/nixpkgs/stable/#emscripten
              	export HOME=$TMPDIR
              	autoreconf -ifv
                emconfigure ./configure \
                  --disable-shared \
                  --without-turbojpeg \
                  --without-simd \
                  --without-arith-enc \
                  --without-arith-dec \
                  --with-build-date=squoosh \
                  --prefix=$out
            '';
            buildPhase = ''
              export HOME=$TMPDIR
              emmake make V=1 -j$(nproc) --trace 
            '';
            installPhase = ''
              make install
              cp *.h $out/include
              cp rdswitch.o $out/lib
            '';
            dontFixup = true;
          };
          installScript = writeShellScriptBin "install.sh" ''
            ${pkgs.coreutils}/bin/rm -rf wasm_build
            ${pkgs.coreutils}/bin/mkdir -p wasm_build
            ${pkgs.rsync}/bin/rsync --chmod=u+w -r ${mozjpeg-squoosh}/* wasm_build/
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
