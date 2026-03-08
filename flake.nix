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
    in {
      packages.${system} = {
        default = pkgs.callPackage ./package.nix {};
        t3code = self.packages.${system}.default;
      };

      overlays.default = final: prev: {
        t3code = final.callPackage ./package.nix {};
      };

      nixosModules.default = { pkgs, ... }: {
        programs.appimage.enable = true;
        programs.appimage.binfmt = true;

        environment.systemPackages = [
          (pkgs.callPackage ./package.nix {})
        ];
      };
    };
}
