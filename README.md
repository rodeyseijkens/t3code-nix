# T3 Code for NixOS

Unofficial Nix package for [T3 Code](https://t3.codes) - a minimal web GUI for coding agents.

## Installation

### NixOS (Recommended)

Add the flake input and import the module:

```nix
{
  inputs = {
    t3code = {
      url = "github:rodeyseijkens/t3code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    }
  };

  outputs = { self, nixpkgs, t3code, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        t3code.nixosModules.default
        # ... your other modules
      ];
    };
  };
}
```

The module automatically:

- Enables AppImage support (`programs.appimage.*`)
- Adds stable t3code to system packages

### Nightly

The flake also exposes `t3code-nightly`, built from the latest upstream nightly
pre-release. Both variants can be installed side by side: they have separate
binaries (`t3code` and `t3code-nightly`) and desktop entries.

### Home Manager

```nix
{
  inputs = {
    t3code = {
      url = "github:rodeyseijkens/t3code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    }
  };

  outputs = { self, nixpkgs, t3code, ... }: {
    homeConfigurations.myhost = home-manager.lib.homeManagerConfiguration {
      modules = [{
        home.packages = [
          t3code.packages.x86_64-linux.t3code
          # Optional: install the nightly alongside the stable release.
          # t3code.packages.x86_64-linux.t3code-nightly
        ];
      }];
    };
  };
}
```

### Overlay

```nix
{
  nixpkgs.overlays = [ t3code.overlays.default ];
  environment.systemPackages = with pkgs; [
    t3code
    t3code-nightly
  ];
}
```

### Direct Run (no install)

```bash
nix run github:rodeyseijkens/t3code-nix --impure
nix run github:rodeyseijkens/t3code-nix#t3code-nightly --impure
```

### Imperative Install

```bash
nix profile install github:rodeyseijkens/t3code-nix#t3code --impure
nix profile install github:rodeyseijkens/t3code-nix#t3code-nightly --impure
```

## Features

- Minimal web GUI for coding agents
- Built on Codex CLI
- Cross-platform (Windows, macOS, Linux)
- Stable and nightly release channels
- AppImage integrated as first-class citizen with desktop entry and icons

## Update Packages

Maintainers can update both channels to the latest upstream releases:

```bash
./update.sh
```

## License

The Nix packaging is MIT. T3 Code itself is proprietary software.

## Links

- [T3 Code](https://t3.codes)
- [T3 Code GitHub](https://github.com/pingdotgg/t3code)
