{
  description = "web service template";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bomper = {
      url = "github:justinrubek/bomper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    gitignore,
    rust-overlay,
    pre-commit-hooks,
    bomper,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          rust-overlay.overlays.default
        ];
      };
      inherit (gitignore.lib) gitignoreSource;
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = gitignoreSource ./.;
        hooks = {
          alejandra.enable = true;
          rustfmt.enable = true;
        };
      };

      rust = pkgs.rust-bin.stable.latest.default;
      rustPackage = pkgs.rustPlatform.buildRustPackage {
        pname = "api";
        version = "0.1.1";

        buildAndTestSubdir = "api";
        src = gitignoreSource ./.;
        cargoLock = {
          lockFile = ./Cargo.lock;
        };
        nativeBuildInputs = [rust];
      };

      bomper-cli = bomper.packages.${system}.cli;
    in rec {
      packages = {
        api = rustPackage;
        default = packages.api;
        api_image = pkgs.dockerTools.buildLayeredImage {
          name = "api";
          tag = "latest";
          contents = [packages.api];
          config = {
            Cmd = ["${packages.api}/bin/api"];
            WorkingDir = "/app";
            ExposedPorts = {"3000/tcp" = {};};
          };
        };
      };
      devShells = {
        default = pkgs.mkShell rec {
          buildInputs = with pkgs; [rust rustfmt cocogitto bomper-cli];
          inherit (pre-commit-check) shellHook;
        };
      };
      apps = {
        api = {
          type = "app";
          program = "${packages.default}/bin/api";
        };
        default = apps.api;
      };
    });
}
