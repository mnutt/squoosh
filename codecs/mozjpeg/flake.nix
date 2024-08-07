{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/24.05";
    };
    mozjpeg = {
      url = "github:mozilla/mozjpeg/v3.3.1";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      mozjpeg,
    }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in
    with pkgs;
    rec {
      packages.${system} = {
        default = stdenv.mkDerivation {
          name = "mozjpeg-squoosh";
          src = ./.;
          nativeBuildInputs = [
            emscripten
            packages.${system}.mozjpeg
          ];
          MOZJPEG = packages.${system}.mozjpeg;
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
          src = mozjpeg;
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
      };
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          autoconf
          automake
          libtool
          emscripten
          pkg-config
        ];
        shellHook = ''
          echo "Path to MozJPEG: ${mozjpeg}"
        '';
      };
    };
}
