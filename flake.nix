{
  description = "akDmx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, crane }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rust-toolchain = pkgs.rust-bin.stable.latest.default;
        craneLib = (crane.mkLib pkgs).overrideToolchain rust-toolchain;

        src = ./.;
        packageJSON = pkgs.lib.importJSON "${src}/package.json";
        pname = packageJSON.name;
        version = packageJSON.version;

        libs = with pkgs; [
          webkitgtk
          gtk3
          cairo
          gdk-pixbuf
          glib
          dbus
          openssl_3
          librsvg
        ];

        buildInputs = with pkgs; [
          bun
          rust-toolchain
          pkg-config
          dbus
          openssl_3
          glib
          gtk3
          libsoup
          webkitgtk
          librsvg
        ];

        node-modules = pkgs.stdenv.mkDerivation {
          pname = "${pname}-node-modules";
          inherit version;
          nativeBuildInputs = with pkgs; [ bun ];
          src = ./.;
          dontConfigure = true;
          impureEnvVars = pkgs.lib.fetchers.proxyImpureEnvVars
            ++ [ "GIT_PROXY_COMMAND" "SOCKS_SERVER" ];
          buildPhase = ''
            bun install --frozen-lockfile --no-progress --ignore-scripts
          '';
          installPhase = ''
            mkdir -p $out/node_modules
            cp -R ./node_modules $out
          '';
          outputHash = "sha256-nMjWaQ/Vz0K/yj2G1D8yRJwGfPoRvKpiFGHAVq8Zoks=";
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
        };

        frontend = pkgs.stdenv.mkDerivation {
          inherit pname version buildInputs;
          src = ./.;

          configurePhase = ''
            runHook preConfigure

            cp -R ${node-modules}/node_modules .
            substituteInPlace node_modules/.bin/vite \
              --replace "/usr/bin/env node" "${pkgs.nodejs-slim_latest}/bin/node"
          '';

          buildPhase = ''
            runHook preBuild

            bun -b run build

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp -R ./dist/* $out

            runHook postInstall
          '';
        };

        cargoArtifacts = craneLib.buildDepsOnly {
          src = "${src}/src-tauri";
          strictDeps = true;
          inherit buildInputs;
        };
        crate = craneLib.buildPackage {
          src = "${src}/src-tauri";
          inherit cargoArtifacts;
        };

        final = pkgs.stdenv.mkDerivation {
          inherit pname version src buildInputs;
        };

      in
      {
        packages.default = frontend;

        apps.default = flake-utils.lib.mkApp {
          drv = final;
        };

        devShells.default = pkgs.mkShell {
          inherit buildInputs;
          shellHook = ''
            LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath libs}:$LD_LIBRARY_PATH
          '';
        };
      }
    );
}
