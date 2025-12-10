{
  inputs,
  callPackage,
  lib,
  linux_latest,
  linux,
  ...
}:
let
  mkCachyKernel = callPackage ./mkCachyKernel.nix { inherit inputs; };
in
builtins.listToAttrs (
  builtins.map (v: lib.nameValuePair v.pname v) [
    (mkCachyKernel {
      pname = "linux-cachyos-latest";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      lto = false;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      lto = true;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts";
      inherit (linux) version src;
      configVariant = "linux-cachyos-lts";
      lto = false;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto";
      inherit (linux) version src;
      configVariant = "linux-cachyos-lts";
      lto = true;
    })
  ]
)
