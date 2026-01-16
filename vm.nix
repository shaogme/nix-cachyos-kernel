{ pkgs ? import <nixpkgs> { }
, inputs ? import ./npins
}:
let
  # Import default.nix to get the kernel packages
  cachyosKernels = import ./default.nix { inherit pkgs inputs; };

  mkVM = kernelPkgName:
    (import (pkgs.path + "/nixos/lib/eval-config.nix") {
      inherit (pkgs) system;
      modules = [
        ./module.nix
        ({ config, lib, pkgs, ... }: {
          boot.kernelPackages = cachyosKernels.${kernelPkgName};
          
          # Minimal configuration for VM
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };
          system.stateVersion = "24.05";
          users.users.root.password = "root";
          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "yes";
          };
        })
      ];
    }).config.system.build.vm;
in
{
  "linux-cachyos-latest" = mkVM "linuxPackages-cachyos-latest";
  "linux-cachyos-lts" = mkVM "linuxPackages-cachyos-lts";
  "linux-cachyos-latest-lto" = mkVM "linuxPackages-cachyos-latest-lto";
  "linux-cachyos-lts-lto" = mkVM "linuxPackages-cachyos-lts-lto";
}
