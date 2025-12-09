# Nix packages for CachyOS Kernel

This repo contains Linux kernels with both [CachyOS patches](https://github.com/CachyOS/kernel-patches) and [CachyOS tunings](https://github.com/CachyOS/linux-cachyos), as well as [CachyOS-patched ZFS module](https://github.com/CachyOS/zfs).

## Which kernel versions are provided?

This repo provides the latest kernel version and the latest LTS kernel version:

```bash
└───packages
    ├───aarch64-linux
        ├───linux-cachyos-latest
        ├───linux-cachyos-latest-lto
        ├───linux-cachyos-lts
        └───linux-cachyos-lts-lto
    └───x86_64-linux
        ├───linux-cachyos-latest
        ├───linux-cachyos-latest-lto
        ├───linux-cachyos-lts
        └───linux-cachyos-lts-lto
```

The kernel versions are automatically kept in sync with Nixpkgs, so once the latest/LTS kernel is updated in Nixpkgs, CachyOS kernels in this repo will automatically catch up.

The kernels ending in `-lto` has Clang+ThinLTO enabled.

For each linux kernel entry under `packages`, we have a corresponding `linuxPackages` entry under `legacyPackages` for easier use in your NixOS configuration, e.g.:

- `linux-cachyos-latest` -> `inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-latest`
- `linux-cachyos-lts-lto` -> `inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-lts-lto`

## How to use kernels

Add this repo to the inputs section of your `flake.nix`:

```nix
{
  inputs = {
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";
  }
}
```

Add the repo's overlay in your NixOS configuration, this will expose the packages in this flake as `pkgs.cachyosKernels.*`.

Then specify `pkgs.cachyosKernels.linuxPackages-cachyos-latest` (or other variants you'd like) in your `boot.kernelPackages` option.

### Example configuration

```nix
{
  nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      (
        { pkgs, ... }:
        {
          nixpkgs.overlays = [ self.overlay ];
          boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
          # ... your other configs
        }
      )
    ];
  };
}
```

## How to use ZFS modules

> Note: CachyOS-patched ZFS module may fail to compile from time to time. Most compilation failures are caused by incompatibilities between kernel and ZFS. Please check [ZFS upstream issues](https://github.com/openzfs/zfs/issues) for any compatibility reports, and try switching between `zfs_2_3`, `zfs_unstable` and `zfs_cachyos`.

To use ZFS module with `linuxPackages-cachyos-*` provided by this flake, point `boot.zfs.package` to `config.boot.kernelPackages.zfs_cachyos`.

```nix
{
  nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      (
        { pkgs, ... }:
        {
          nixpkgs.overlays = [ self.overlay ];
          boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

          # ZFS config
          boot.supportedFilesystems.zfs = true;
          boot.zfs.package = config.boot.kernelPackages.zfs_cachyos;

          # ... your other configs
        }
      )
    ];
  };
}
```

If you want to construct your own `linuxPackages` attrset with `linuxKernel.packagesFor (path to your kernel)`, you can directly reference the `zfs-cachyos` attribute in this flake's `packages` / `legayPackages` output, or the `cachyosKernels` overlay:

```nix
{
  nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      (
        { pkgs, ... }:
        {
          nixpkgs.overlays = [ self.overlay ];
          boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

          # ZFS config
          boot.supportedFilesystems.zfs = true;
          boot.zfs.package = pkgs.cachyosKernels.zfs-cachyos.override {
            kernel = config.boot.kernelPackages.kernel;
          };

          # ... your other configs
        }
      )
    ];
  };
}
```
