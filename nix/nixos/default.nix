{ overlays }:

{
  pgs = {
    imports = [ ./pgs.nix ];
    nixpkgs = { inherit overlays; };
  };
}
