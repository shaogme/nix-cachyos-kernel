{
  inputs,
  callPackage,
  kernel ? null,
  lib,
  fetchFromGitHub,
}:
let
  versionJson = lib.importJSON ./version.json;
  zfsGeneric = callPackage "${inputs.nixpkgs.outPath}/pkgs/os-specific/linux/zfs/generic.nix" {
    inherit kernel;
  };
in
# https://github.com/chaotic-cx/nyx/blob/aacb796ccd42be1555196c20013b9b674b71df75/pkgs/linux-cachyos/packages-for.nix#L99
(zfsGeneric {
  kernelModuleAttribute = "zfs_cachyos";
  kernelMinSupportedMajorMinor = "1.0";
  kernelMaxSupportedMajorMinor = "99.99";
  enableUnsupportedExperimentalKernel = true;
  version = builtins.elemAt (lib.splitString "-" versionJson.zfs_branch) 1;
  tests = { };
  maintainers = with lib.maintainers; [
    pedrohlc
  ];
  hash = "";
  extraPatches = [ ];
}).overrideAttrs
  (prevAttrs: {
    src = fetchFromGitHub {
      owner = "cachyos";
      repo = "zfs";
      inherit (versionJson) rev hash;
    };
    postPatch = builtins.replaceStrings [ "grep --quiet '^Linux-M" ] [ "# " ] prevAttrs.postPatch;
  })
