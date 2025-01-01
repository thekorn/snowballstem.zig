{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zig-overlay.url = "github:mitchellh/zig-overlay";
    zls-master = {
      url = "github:zigtools/zls";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zig-overlay.follows = "zig-overlay";
    };

  };

  outputs = { self, flake-utils, nixpkgs, zig-overlay, zls-master }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };
      in {
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            zig-overlay.packages.${system}."master-2024-11-30"
            zls-master.packages.${system}.default
            pkg-config

            lldb
            hyperfine
          ];
          buildInputs = with pkgs; [
              glfw
          ];

          shellHook = ''
            # We unset some NIX environment variables that might interfere with the zig
            # compiler.
            # Issue: https://github.com/ziglang/zig/issues/18998
            unset NIX_CFLAGS_COMPILE
            #unset NIX_LDFLAGS
          '';

          PKG_CONFIG_PATH = "${pkgs.glfw}/lib/pkgconfig";
        };
      }
    );
}
