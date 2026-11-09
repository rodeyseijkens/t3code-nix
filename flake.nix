{
  description = "T3 Code - Minimal web GUI for coding agents";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      versions = import ./versions.nix;
      t3code = pkgs.callPackage ./package.nix {
        inherit (versions.stable) version hash;
      };
      t3code-nightly = pkgs.callPackage ./package.nix {
        pname = "t3code-nightly";
        inherit (versions.nightly) version hash;
      };
    in {
      packages.${system} = {
        default = t3code;
        inherit t3code t3code-nightly;
      };

      overlays.default = final: prev: {
        t3code = final.callPackage ./package.nix {
          inherit (versions.stable) version hash;
        };
        t3code-nightly = final.callPackage ./package.nix {
          pname = "t3code-nightly";
          inherit (versions.nightly) version hash;
        };
      };

      nixosModules.default = { pkgs, ... }: {
        programs.appimage.enable = true;
        programs.appimage.binfmt = true;

        environment.systemPackages = [
          self.packages.${system}.t3code
        ];
      };
    };
}
