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
    };
}
