{ config, lib, pkgs, ... }:

let
  cfg = config.services.cachyos-kernels;
in
{
  options.services.cachyos-kernels = {
    enable = lib.mkEnableOption "Enable CachyOS Kernels overlay and cache";

    useCachix = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use the designated CachyOS Cachix binary cache.";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.settings = lib.mkIf cfg.useCachix {
      substituters = [
        "https://cachyos-kernels.cachix.org"
      ];
      trusted-public-keys = [
        "cachyos-kernels.cachix.org-1:NmbrMDHqVswfrt4bSu9CTcCQwCgJA+ZfKG894X96RA8="
      ];
    };

    nixpkgs.overlays = [
      (final: prev: {
        cachyosKernels = import ./default.nix {
          pkgs = final;
        };
      })
    ];
  };
}
