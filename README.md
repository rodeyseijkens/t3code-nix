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
- Adds t3code to system packages

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
          t3code.packages.x86_64-linux.default
        ];
      }];
    };
  };
}
```

### Direct Run (no install)

```bash
nix run github:rodeyseijkens/t3code-nix --impure
```

### Imperative Install

```bash
nix profile install github:rodeyseijkens/t3code-nix --impure
```

## Features

- Minimal web GUI for coding agents
- Built on Codex CLI
- Cross-platform (Windows, macOS, Linux)
- AppImage integrated as first-class citizen with desktop entry and icons

## Update Package

Maintainers can update to the latest version:

```bash
./update.sh
```

## License

The Nix packaging is MIT. T3 Code itself is proprietary software.

## Links

- [T3 Code](https://t3.codes)
- [T3 Code GitHub](https://github.com/pingdotgg/t3code)
