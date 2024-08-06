{
  inputs = {
    mozjpeg = {
      url = "github:mozilla/mozjpeg/v3.3.1";
      flake = false;

      # type = "github";
      # owner = "mozilla";
      # repo = "mozjpeg";
      # rev = "v3.3.1";
      # hash = "sha256-frpQdkk7bJE5qbV70fdL1FsC4eI0Fm8FWshqBQxCRtk=";
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
        nativeBuildInputs = [ emscripten packages.${system}.mozjpeg ];
        MOZJPEG = packages.${system}.mozjpeg;
        dontConfigure = true;
        buildPhase = ''
          export HOME=$TMPDIR
          emmake make -j$(nproc)
        '';
        installPhase = ''
          mkdir -p $out
          cp 
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
        preConfigure = ''
            # $HOME is required for Emscripten to work.
            # See: https://nixos.org/manual/nixpkgs/stable/#emscripten
          	export HOME=$TMPDIR
          	autoreconf -if
        '';
        # configurePhase = ''

        #     runHook preConfigure
        #     emconfigure ./configure $configureFlags
        #     runHook postConfigure
        # '';
        configureScript = "emconfigure ./configure";
        configureFlags = [
          "--disable-shared"
          "--without-turbojpeg"
          "--without-simd"
          "--without-arith-enc"
          "--without-arith-dec"
          "--with-build-date=squoosh"
        ];
        buildFlags = [
          "libjpeg.la"
          "rdswitch.o"
        ];
        buildPhase = ''
          	emmake make -j$(nproc) $buildFlags
        '';
        installPhase = ''
            mkdir -p $out/lib
            mkdir -p $out/include
            cp .libs/libjpeg.a $out/lib
            cp rdswitch.o $out/lib
            cp *.h $out/include
        '';
        checkPhase = ''
          true
        '';
      };
      };
      devShells.${system}.default = pkgs.mkShell {
        shellHook = ''
          echo "Path to MozJPEG: ${mozjpeg}"
        '';
      };
    };
}
