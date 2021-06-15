{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    utils.url = "github:numtide/flake-utils";
    grin.url = "github:yatima-inc/grin";
    naersk-src.url = "github:nmattia/naersk";
  };

  outputs =
    { self
    , nixpkgs
    , utils
    , naersk-src
    , grin
    }:
    utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; overlays = [ (import ./nix/rust-overlay.nix) ]; };
      rust = import ./nix/rust.nix { inherit pkgs; };
      naersk = naersk-src.lib."${system}".override {
        rustc = rust;
        cargo = rust;
      };

      crateName = "yatima";

      project = import ./yatima.nix {
        inherit pkgs rust naersk;
      };

    in
    {
      packages.${crateName} = project;

      defaultPackage = self.packages.${system}.${crateName};

      # `nix run`
      apps.${crateName} = utils.lib.mkApp {
        drv = self.packages.${system}.${crateName};
      };
      defaultApp = self.packages.${system}.${crateName};

      # `nix develop`
      devShell = pkgs.mkShell {
        inputsFrom = builtins.attrValues self.packages.${system};
        nativeBuildInputs = [ rust ];
        buildInputs = with pkgs; [
          rust-analyzer
          clippy
          rustfmt
          grin
        ];
      };
    });
}
