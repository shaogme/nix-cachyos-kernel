{
  description = "CachyOS Kernels";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    cachyos-kernel = {
      url = "github:CachyOS/linux-cachyos";
      flake = false;
    };
    cachyos-kernel-patches = {
      url = "github:CachyOS/kernel-patches";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      legacyPackages = forAllSystems (system:
        import ./default.nix {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          inherit inputs;
        }
      );

      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.lib.filterAttrs (_: pkgs.lib.isDerivation) self.legacyPackages.${system}
      );

      overlays.default = final: prev: {
        cachyosKernels = import ./default.nix {
          pkgs = final;
          inherit inputs;
        };
      };

      nixosModules.default = import ./module.nix;

      nixosConfigurations =
        let
          mkVM = kernelPkg: nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              self.nixosModules.default
              ({ pkgs, ... }: {
                boot.kernelPackages = pkgs.cachyosKernels.${kernelPkg};
                
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
          };
        in
        {
          "linux-cachyos-latest" = mkVM "linuxPackages-cachyos-latest";
          "linux-cachyos-lts" = mkVM "linuxPackages-cachyos-lts";
          "linux-cachyos-latest-lto" = mkVM "linuxPackages-cachyos-latest-lto";
          "linux-cachyos-lts-lto" = mkVM "linuxPackages-cachyos-lts-lto";
        };
    };
}
