{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.05";
    flake-utils.url = "github:numtide/flake-utils";
    fenix.url = "github:nix-community/fenix";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      fenix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        target = "wasm32-unknown-unknown";
        pkgs = nixpkgs.legacyPackages.${system};
        toolchain =
          with fenix.packages.${system};
          combine [
            stable.rustc
            stable.cargo
            targets.${target}.stable.rust-std
          ];
        src = ./.;

        cargoLock = pkgs.lib.importTOML "${src}/Cargo.lock";
        wasm-bindgen-version =
          (pkgs.lib.lists.findFirst (x: x.name == "wasm-bindgen") null cargoLock.package).version;
        wasm-bindgen-src = pkgs.fetchCrate {
          pname = "wasm-bindgen-cli";
          version = wasm-bindgen-version;
          sha256 = "sha256-HTElSB76gqCpDu8S0ZJlfd/S4ftMrbwxFgJM9OXBRz8=";
        };
        wasm-bindgen = pkgs.rustPlatform.buildRustPackage {
          name = "wasm-bindgen-cli";
          buildInputs = [
            pkgs.curl
            pkgs.darwin.apple_sdk.frameworks.Security
          ];
          src = wasm-bindgen-src;
          # cargoSha256 = "sha256-I6fsBSyqiubbMKyxXhMebKnpRZdB6bHHSB+NyrrqSnY="; 
          cargoLock = {
            lockFile = "${wasm-bindgen-src}/Cargo.lock";
          };
          doCheck = false;
        };
      in
      with pkgs;
      {
        packages = rec {
          default = resize-squoosh;
          resize-squoosh = stdenv.mkDerivation {
            name = "squoosh-resize";
            inherit src;
            nativeBuildInputs = [
              #naersk'
              toolchain
              curl
              iconv
              # wasm-pack
              wasm-bindgen
            ];
            dontConfigure = true;
            # postUnpack = ''
            #   export CARGO_HOME=$TMPDIR/.cargo
            #   cargo install -f wasm-bindgen-cli --version ${wasm-bindgen-version}
            # '';
            buildPhase = ''
              runHook preBuild
              export CARGO_HOME=$TMPDIR/.cargo
              cargo build --target wasm32-unknown-unknown -r
              wasm-bindgen --target web --out-dir $out ./target/wasm32-unknown-unknown/release/*.wasm
              runHook postBuild
            '';
            dontInstall = true;
            # installPhase = ''
            #   mkdir -p $out
            #   cp -r pkg/* $out
            # '';
          };

          installScript = writeShellScriptBin "install.sh" ''
            ${pkgs.coreutils}/bin/mkdir -p wasm_build
            ${pkgs.rsync}/bin/rsync --chmod=u+w -r ${self.packages.${system}.resize-squoosh}/* wasm_build/
          '';
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
