{ pkgs ? (
    let
      inherit (builtins) fetchTree fromJSON readFile;
      inherit ((fromJSON (readFile ../../flake.lock)).nodes) nixpkgs gomod2nix;
    in
    import (fetchTree nixpkgs.locked) {
      overlays = [
        (import "${fetchTree gomod2nix.locked}/overlay.nix")
      ];
    }
  )
, buildGoApplication ? pkgs.buildGoApplication
, version
}:

buildGoApplication {
  pname = "migrate";
  inherit version;
  pwd = ../..;
  src = ../..;
  subPackages = [
    "/cmd/scripts/migrate"
  ];
  modules = ../../gomod2nix.toml;
}
