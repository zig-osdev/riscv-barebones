{
  inputs = {
    utils.url = github:numtide/flake-utils;
    zigpkg.url = github:mitchellh/zig-overlay;
    zlspkg.url = github:zigtools/zls;
  };

  outputs = { self, nixpkgs, zigpkg, zlspkg, utils }:
    utils.lib.eachDefaultSystem(system:
      let
        zig = zigpkg.packages.${system};
        zls = zlspkg.packages.${system};
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ zig.master zls.default ];
          buildInputs = with pkgs; [ qemu ];
        };
      });
}
