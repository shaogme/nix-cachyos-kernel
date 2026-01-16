{ pkgs ? import <nixpkgs> { }
, inputs ? import ./npins
}:
let
  inherit (pkgs) lib;
  callPackage = lib.callPackageWith (pkgs // { inherit inputs; });
in
lib.removeAttrs
  (callPackage ./kernel-cachyos/packages.nix { })
  [ "override" "overrideDerivation" ]
