{
  perSystem = { pkgs, inputs', ... }:
    let
      callPackage = pkgs.darwin.apple_sdk_11_0.callPackage or pkgs.callPackage;
      callPackage' = path: callPackage path {
        inherit (inputs'.gomod2nix.legacyPackages) buildGoApplication;
        version = "v3.0.2";
      };
    in
    {
      packages = rec {
        default = pgs;
        pgs = callPackage' ./pkgs/pgs.nix;
        migrate = callPackage' ./pkgs/migrate.nix;
      };
    };
}
