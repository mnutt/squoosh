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

      variantOptions = {
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
        inherit (pkgs) lib stdenv callPackage;
        buildSquooshCppCodec = callPackage (import ../../nix/squoosh-cxx-builder) {};
        mkInstallable = callPackage (import ../../nix/mk-installable) {};

        builder =
          name:
          { simd }:
          {
            "webp-squoosh" = buildSquooshCppCodec {
              name = "webp-squoosh-${name}";
              src = lib.sources.sourceByRegex ./. ["Makefile" "enc(/.+)?" "dec(/.+)?"]; 
              nativeBuildInputs = [
                pkgs.emscripten
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
            "webp" = stdenv.mkDerivation {
              name = "webp-${name}";
              src = webp-src;
              nativeBuildInputs = [
                pkgs.emscripten
                pkgs.cmake
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
          };

        suffixAttrNames = suffix: attrs:
          lib.mapAttrs'
            (name: val:
              lib.nameValuePair
              "${name}${suffix}"
              val)
            attrs;
        forAllVariants = 
          {builder, variants}: 
            lib.lists.foldl
              (acc: v: acc//v)
              {}
              (lib.mapAttrsToList
                (variantName: value: 
                  suffixAttrNames "-${variantName}" (builder variantName value))
                variants
              );

        packageVariants = forAllVariants {
          inherit builder;
          variants = variantOptions;
        };

        defaultPackage = let
          variants = lib.mapAttrs (name: opts: packageVariants."webp-squoosh-${name}") variantOptions;
          copyCommands = lib.concatLines (lib.mapAttrsToList (name: path: "cp -r ${path} $out/${name}") variants);
        in
        stdenv.mkDerivation {
          name = "all-variants";
          phases = ["buildPhase"];
          buildPhase = ''
            mkdir -p $out;
            ${copyCommands}
          '';
        };
      in

      mkInstallable {
        packages = packageVariants // {default = defaultPackage;};
      }
    );
}
