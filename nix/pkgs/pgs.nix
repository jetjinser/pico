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
  pname = "pgs";
  inherit version;
  pwd = ../..;
  src = ../..;
  subPackages = [
    "/cmd/pgs/ssh"
    "/cmd/pgs/web"
  ];
  installPhase = ''
    runHook preInstall

    mkdir -p $out
    dir="$GOPATH/bin"
    [ -e "$dir" ] && cp -r $dir $out

    mkdir -p $out/pgs
    cp -r ./pgs/html $out/pgs/html
    cp -r ./pgs/public $out/pgs/public

    runHook postInstall
  '';
  modules = ../../gomod2nix.toml;
}
