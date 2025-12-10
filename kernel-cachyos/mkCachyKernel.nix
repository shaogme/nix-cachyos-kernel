{
  inputs,
  lib,
  callPackage,
  buildLinux,
  stdenv,
  kernelPatches,
  ...
}:
lib.makeOverridable (
  {
    pname,
    version,
    src,

    # Kernel config variant to be used as defconfig, e.g. "linux-cachyos-lts".
    # See https://github.com/CachyOS/linux-cachyos for available values.
    configVariant,

    # Set to true to enable Clang+ThinLTO.
    lto,

    # Patches to be applied in patchedSrc phase. This is different from buildLinux's kernelPatches.
    prePatch ? "",
    patches ? [ ],
    postPatch ? "",

    # See nixpkgs/pkgs/os-specific/linux/kernel/generic.nix for additional options.
    # Additional args are passed to buildLinux.
    ...
  }@args:
  let
    helpers = callPackage ../helpers.nix { };
    inherit (helpers) stdenvLLVM ltoMakeflags;

    splitted = lib.splitString "-" version;
    ver0 = builtins.elemAt splitted 0;
    major = lib.versions.pad 2 ver0;

    cachyosConfigFile = "${inputs.cachyos-kernel.outPath}/${configVariant}/config";
    cachyosPatch = "${inputs.cachyos-kernel-patches.outPath}/${major}/all/0001-cachyos-base-all.patch";

    # buildLinux doesn't accept postPatch, so adding config file early here
    patchedSrc = stdenv.mkDerivation {
      pname = "${pname}-src";
      inherit version src prePatch;
      patches = [
        kernelPatches.bridge_stp_helper.patch
        kernelPatches.request_key_helper.patch
        cachyosPatch
      ]
      ++ patches;
      postPatch = ''
        for DIR in arch/*/configs; do
          install -Dm644 ${cachyosConfigFile} $DIR/cachyos_defconfig
        done
      ''
      + postPatch;
      dontConfigure = true;
      dontBuild = true;
      dontFixup = true;
      installPhase = ''
        mkdir -p $out
        cp -r * $out/
      '';
    };
  in
  buildLinux (
    (lib.removeAttrs args [
      "pname"
      "version"
      "src"
      "configVariant"
      "lto"
      "prePatch"
      "patches"
      "postPatch"
    ])
    // {
      inherit pname version;
      src = patchedSrc;
      stdenv = args.stdenv or (if lto then stdenvLLVM else stdenv);

      extraMakeFlags = (lib.optionals lto ltoMakeflags) ++ (args.extraMakeFlags or [ ]);

      defconfig = args.defconfig or "cachyos_defconfig";

      # Clang has some incompatibilities with NixOS's default kernel config
      ignoreConfigErrors = args.ignoreConfigErrors or lto;

      structuredExtraConfig =
        with lib.kernel;
        (
          {
            NR_CPUS = lib.mkForce (option (freeform "8192"));

            # Follow NixOS default config to not break etc overlay
            OVERLAY_FS = module;
            OVERLAY_FS_REDIRECT_DIR = no;
            OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW = yes;
            OVERLAY_FS_INDEX = no;
            OVERLAY_FS_XINO_AUTO = no;
            OVERLAY_FS_METACOPY = no;
            OVERLAY_FS_DEBUG = no;
          }
          // (lib.optionalAttrs lto {
            LTO_NONE = no;
            LTO_CLANG_THIN = yes;
          })
          // (args.structuredExtraConfig or { })
        );

      extraMeta = {
        description = "Linux CachyOS Kernel" + lib.optionalString lto " with Clang+ThinLTO";
      }
      // (args.extraMeta or { });

      extraPassthru = {
        inherit cachyosConfigFile cachyosPatch;
      }
      // (args.extraPassthru or { });
    }
  )
)
