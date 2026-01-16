{ pkgs ? import <nixpkgs> { }
, inputs ? import ./npins
}:
let
  inherit (pkgs) lib;
  callPackage = lib.callPackageWith (pkgs // { inherit inputs; });

  kernels = callPackage ./kernel-cachyos/default.nix { };
  kernelPackages = callPackage ./kernel-cachyos/packages.nix { };
in
kernels // (lib.removeAttrs kernelPackages [ "override" "overrideDerivation" ])
