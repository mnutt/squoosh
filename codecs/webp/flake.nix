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
    let
      packageVariants = {
        base = {
          simd = false;
        };
        simd = {
          simd = true;
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib stdenv runCommand emscripten writeShellScriptBin cmake;
        packageVariantBuilder =
          name:
          { simd }@variantOptions:
          {
            "webp-squoosh-${name}" = stdenv.mkDerivation {
              name = "webp-squoosh-${name}";
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
                self.packages.${system}."webp-${name}"
              ];
              WEBP = self.packages.${system}."webp-${name}";
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
            "webp-${name}" = stdenv.mkDerivation {
              name = "webp-${name}";
              src = webp-src;
              nativeBuildInputs = [
                emscripten
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
                    ${if simd then "-DWEBP_ENABLE_SIMD=1" else ""} \
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
            "install-${name}" = writeShellScriptBin "install.sh" ''
              ${pkgs.coreutils}/bin/mkdir -p wasm_build/${name}
              ${pkgs.rsync}/bin/rsync --chmod=u+w -r ${
                self.packages.${system}."webp-squoosh-${name}"
              }/* wasm_build/${name}
            '';
          };

        packages = lib.foldl (acc: v: acc//v) {} (lib.mapAttrsToList packageVariantBuilder packageVariants);

        joinLines = lines: lib.foldl (text: line: text + line) "" lines;

        globalInstallerCode = joinLines (lib.lists.map (variantName: ''
          ${self.packages.${system}."install-${variantName}"}/bin/install.sh
        '') (lib.attrNames packageVariants));
      in

      {
        packages = packages // {
          installScript = writeShellScriptBin "install.sh" globalInstallerCode;
        };
        apps = {
          install = {
            type = "app";
            program = "${self.packages.${system}.installScript}/bin/install.sh";
          };
        };
      }

    );
}
