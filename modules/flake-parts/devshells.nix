{
  perSystem =
    { pkgs, self', ... }:
    {
      # GSD Pi: `nix develop .#gsd` で `gsd` が使える
      devShells.gsd = pkgs.mkShell {
        packages = [ self'.packages.gsd-pi ];
      };
    };
}
