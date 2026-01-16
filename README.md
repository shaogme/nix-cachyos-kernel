# Nix CachyOS Kernel

本项目致力于将 [CachyOS](https://cachyos.org/) 的高性能内核（包含 kernel-patches 和调优配置）移植到 NixOS 系统中。

## 特性

*   **高性能**: 集成 CachyOS 的各类优化补丁和配置。
*   **多版本支持**:不仅包含最新的稳定版内核，还支持 LTO、Hardened 以及多种 CPU 调度器变体（如 BORE, EEVDF, SCX 等）。
*   **二进制缓存**: 提供 Cachix 缓存，加速构建。
*   **ZFS 支持**: 提供与内核版本匹配的 ZFS 模块。

## 使用方法

提供 **Flake** 和 **Npins** (即传统非 Flake) 两种使用方式。

### 方式 1: Nix Flake (推荐)

在你的 `flake.nix` 中添加输入源，并在 NixOS 配置中导入模块。

1.  **添加 inputs**:

    ```nix
    {
      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        
        # 添加 CachyOS Kernel
        cachyos-kernels.url = "github:shaogme/nix-cachyos-kernel";
      };
      
      outputs = { self, nixpkgs, cachyos-kernels, ... }: {
        nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # 导入模块
            cachyos-kernels.nixosModules.default
            ./configuration.nix
          ];
        };
      };
    }
    ```

2.  **配置系统 (configuration.nix)**:

    启用模块并选择内核：

    ```nix
    { pkgs, ... }:
    {
      # 1. 启用 CachyOS Kernels 模块
      # 这会自动添加 overlay 并配置二进制缓存 (Cachix)
      services.cachyos-kernels.enable = true;

      # 2. 选择内核
      # 注意：内核包位于 pkgs.cachyosKernels 命名空间下
      
      # 示例：使用最新的 CachyOS 内核
      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

      # 示例：使用带有 BORE 调度器的内核
      # boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore;
      
      # 示例：启用 ZFS 支持
      # boot.supportedFilesystems = [ "zfs" ];
      # boot.zfs.package = pkgs.cachyosKernels.zfs_cachyos;
    }
    ```

### 方式 2: Npins (传统方式)

如果你不使用 Flakes，可以通过 `npins` 管理依赖。

1.  **初始化并添加源**:

    ```bash
    npins init
    npins add github shaogme nix-cachyos-kernel
    ```

2.  **配置系统**:

    在你的 `configuration.nix` 或 `default.nix` 中导入模块：

    ```nix
    { pkgs, config, lib, ... }:
    let
      # 读取 npins 源
      sources = import ./npins;
      
      # 获取 nix-cachyos-kernel 路径
      cachyos-kernel-path = sources.nix-cachyos-kernel;
    in
    {
      imports = [
        # 从源码路径直接导入 NixOS 模块
        "${cachyos-kernel-path}/module.nix"
      ];

      # 1. 启用模块
      services.cachyos-kernels.enable = true;

      # 2. 选择内核 (同样位于 pkgs.cachyosKernels 下)
      boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
    }
    ```

## 配置选项

模块提供以下配置选项：

*   `services.cachyos-kernels.enable`: (布尔值) 启用 CachyOS Kernels overlay 和必要的设置。默认为 `false`。
*   `services.cachyos-kernels.useCachix`: (布尔值) 是否使用官方提供的 Cachix 二进制缓存 (`https://cachyos-kernels.cachix.org`)。默认为 `true`。

## 提供的内核版本

### Flake Outputs 列表

```text
└───packages
    └───x86_64-linux
        # Latest kernel, provide all LTO/CPU arch variants
        ├───linux-cachyos-latest
        ├───linux-cachyos-latest-x86_64-v2
        ├───linux-cachyos-latest-x86_64-v3
        ├───linux-cachyos-latest-x86_64-v4
        ├───linux-cachyos-latest-zen4
        ├───linux-cachyos-latest-lto
        ├───linux-cachyos-latest-lto-x86_64-v2
        ├───linux-cachyos-latest-lto-x86_64-v3
        ├───linux-cachyos-latest-lto-x86_64-v4
        ├───linux-cachyos-latest-lto-zen4
        # LTS kernel, provide LTO variants
        ├───linux-cachyos-lts
        ├───linux-cachyos-lts-lto
        # Additional CachyOS kernel variants
        ├───linux-cachyos-bmq
        ├───linux-cachyos-bmq-lto
        ├───linux-cachyos-bore
        ├───linux-cachyos-bore-lto
        ├───linux-cachyos-deckify
        ├───linux-cachyos-deckify-lto
        ├───linux-cachyos-eevdf
        ├───linux-cachyos-eevdf-lto
        ├───linux-cachyos-hardened
        ├───linux-cachyos-hardened-lto
        ├───linux-cachyos-rc
        ├───linux-cachyos-rc-lto
        ├───linux-cachyos-rt-bore
        ├───linux-cachyos-rt-bore-lto
        ├───linux-cachyos-server
        └───linux-cachyos-server-lto
```

**注意**: 以上名称为 Flake `packages` 输出中的名称（即内核 Derivation 本身）。
在 NixOS 配置 `boot.kernelPackages` 时，请使用对应的 `linuxPackages` 名称（通常加前缀 `linuxPackages-`）。
例如：`linux-cachyos-latest` 对应 `pkgs.cachyosKernels.linuxPackages-cachyos-latest`。

## 二进制缓存

启用 `services.cachyos-kernels.enable = true` 后，默认会自动配置 Cachix 缓存：

*   **URL**: `https://cachyos-kernels.cachix.org`
*   **Public Key**: `cachyos-kernels.cachix.org-1:NmbrMDHqVswfrt4bSu9CTcCQwCgJA+ZfKG894X96RA8=`

这将大大缩短安装时间，避免本地编译内核。

## 致谢

*   [CachyOS Team](https://cachyos.org/)
*   [linux-cachyos](https://github.com/CachyOS/linux-cachyos)
