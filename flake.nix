{
  inputs = {
    utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem(system:
      let pkgs = import nixpkgs { inherit system; }; in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ zig zls ];
          buildInputs = with pkgs; [ qemu ];
        };
      });
}
