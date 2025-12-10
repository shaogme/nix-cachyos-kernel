{
  inputs,
  callPackage,
  lib,
  linuxKernel,
  ...
}:
let
  helpers = callPackage ../helpers.nix { };
  inherit (helpers) kernelModuleLLVMOverride;

  kernels = lib.filterAttrs (_: lib.isDerivation) (callPackage ./. { inherit inputs; });
in
lib.mapAttrs' (
  n: v:
  let
    zfsPackage = callPackage ../zfs-cachyos {
      inherit inputs;
      kernel = v;
    };

    packages = kernelModuleLLVMOverride (
      (linuxKernel.packagesFor v).extend (
        final: prev: {
          zfs_cachyos = zfsPackage;
        }
      )
    );
  in
  lib.nameValuePair "linuxPackages-${lib.removePrefix "linux-" n}" packages
) kernels
