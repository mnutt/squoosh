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
      {
        packages = rec {
          default = mozjpeg-squoosh;
          mozjpeg-squoosh = stdenv.mkDerivation {
            name = "mozjpeg-squoosh";
            src = ./.;
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
              cp enc/*.{wasm,js} $out
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
            ${pkgs.coreutils}/bin/mkdir build
            ${pkgs.coreutils}/bin/cp ${mozjpeg-squoosh}/* build/
          '';
        };
        apps = {
          install = {
            type = "app";
            # program = "
          };
        };
      }
    );
}
