{ sources ? import ./sources.nix
}:
let
  # default nixpkgs
  pkgs = import sources.nixpkgs { overlays = [ (import ./rust-overlay.nix) ]; };

  # gitignore.nix 
  gitignoreSource = (import sources."gitignore.nix" { inherit (pkgs) lib; }).gitignoreSource;

  pre-commit-hooks = (import sources."pre-commit-hooks.nix");

  # nixpkgs-mozilla = pkgs.callPackage (sources.nixpkgs-mozilla + "/package-set.nix") { };
  rust = import ./rust.nix { inherit pkgs; };

  # grinProject = import sources.grin { };
  # grin = grinProject.grin.components.exes.grin;
  naersk = pkgs.callPackage sources.naersk {
    rustc = rust;
    cargo = rust;
  };

  src = gitignoreSource ./..;
in
{
  inherit pkgs src;

  # provided by shell.nix
  devTools = {
    inherit (pkgs) niv wasm-pack wasmtime valgrind openssl pkg-config;
    inherit (pre-commit-hooks) pre-commit nixpkgs-fmt nix-linter rustfmt clippy;
    inherit rust;
    # inherit grin;
  };

  # to be built by github actions
  ci = {
    pre-commit-check = pre-commit-hooks.run {
      inherit src;
      hooks = {
        shellcheck.enable = true;
        nixpkgs-fmt.enable = true;
        nix-linter.enable = true;
        # cargo-check.enable = true;
        # rustfmt.enable = true;
        # clippy.enable = true;
        html-tidy.enable = true;
      };
      # generated files
      excludes = [ "^nix/sources\.nix$" ];
    };
    yatima-native = import ../yatima.nix {
      inherit sources pkgs rust naersk;
    };
    yatima-wasi = import ../yatima.nix {
      inherit sources pkgs rust naersk;
      target = "wasm32-wasi";
    };
  };
}
