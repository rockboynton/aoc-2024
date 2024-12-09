{
  description = "Advent of Code 2024";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig.url = "github:mitchellh/zig-overlay";
    zls.url = "github:zigtools/zls";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
    ...
  } @ inputs: let
    overlays = [
      # Other overlays
      (final: prev: rec {
        zig = inputs.zig.packages.${prev.system}.master;
        zls = inputs.zls.packages.${prev.system}.zls.overrideAttrs (old: {
          nativeBuildInputs = [ zig ];
        });
      })
      (import rust-overlay)
    ];

    # Our supported systems are the same supported systems as the Zig binaries
    systems = builtins.attrNames inputs.zig.packages;
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {inherit overlays system;};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" "rust-analyzer" ];
            })
            zig
            zls
            lldb_19
          ];
        };
      }
    );
}
