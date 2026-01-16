# CachyOS Kernel Nix 移植项目

本项目致力于将 CachyOS 的高性能内核（包含 [CachyOS 补丁集](https://github.com/CachyOS/kernel-patches) 和 [CachyOS 调优配置](https://github.com/CachyOS/linux-cachyos)）以及 [适配 CachyOS 的 ZFS 模块](https://github.com/CachyOS/zfs) 移植到 Nix/NixOS 系统中。

[![built with garnix](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fxddxdd%2Fnix-cachyos-kernel)](https://garnix.io/repo/xddxdd/nix-cachyos-kernel)

> **注意**: 如果 Garnix 显示 "all builds failed"，通常意味着免费构建时长已耗尽。我还有一个[私人 Hydra CI](https://hydra.lantian.pub/jobset/lantian/nix-cachyos-kernel) 在持续构建这些内核。

## 提供的内核版本

本项目提供以下内核变体，与 [CachyOS 上游定义](https://github.com/CachyOS/linux-cachyos?tab=readme-ov-file#kernel-variants--schedulers) 保持一致：

*   **Latest (最新版)**: 提供多种 CPU 架构优化 (x86-64-v2/v3/v4) 及 LTO 变体。
    *   `linux-cachyos-latest`
    *   `linux-cachyos-latest-lto` (Clang + ThinLTO)
    *   *(以及针对特定 CPU 微架构的版本，如 `zen4`, `x86_64-v3` 等)*
*   **LTS (长期支持版)**: 
    *   `linux-cachyos-lts`
    *   `linux-cachyos-lts-lto`
*   **特色调度器版本**:
    *   `bmq`, `bore`, `eevdf`, `rt-bore` (实时内核)
*   **硬件专用版**:
    *   `deckify` (Steam Deck 优化)
    *   `server` (服务器优化)
    *   `hardened` (强化安全版)

这些内核版本会自动与 Nixpkgs 保持同步。

你可以运行 `nix-env -f . -qa` 或查看 `default.nix` 了解当前所有可用的包名。

## 如何使用

### 1. 引入本项目

由于本项目已移除 Flake 支持，推荐通过 `fetchTarball` 或 `npins` 等方式引入。

**方法 A: 使用 `fetchTarball` (简单，适合不想折腾的用户)**

在你的 NixOS 配置中：

```nix
{ pkgs, config, lib, ... }:
let
  nix-cachyos-kernel = import (builtins.fetchTarball "https://github.com/xddxdd/nix-cachyos-kernel/archive/master.tar.gz") {
    inherit pkgs;
  };
in
{
  boot.kernelPackages = nix-cachyos-kernel.linuxPackages-cachyos-latest;
  
  # 如果需要 ZFS
  boot.supportedFilesystems.zfs = true;
  boot.zfs.package = nix-cachyos-kernel.zfs-cachyos;
}
```

**方法 B: 使用 `npins` (推荐，可锁定版本)**

1.  初始化 npins 并添加源:
    ```bash
    npins init
    npins add github xddxdd/nix-cachyos-kernel
    ```
2.  在配置中导入:
    ```nix
    { pkgs, ... }:
    let
      sources = import ./npins;
      nix-cachyos-kernel = import sources.nix-cachyos-kernel { inherit pkgs; };
    in
    {
      boot.kernelPackages = nix-cachyos-kernel.linuxPackages-cachyos-latest;
    }
    ```

### 2. 配置 ZFS

CachyOS 内核可能与标准 ZFS 模块不兼容，你需要使用本项目提供的 ZFS 包。

```nix
{
  boot.supportedFilesystems.zfs = true;
  # 使用与当前选择的 CachyOS 内核匹配的 ZFS 模块
  boot.zfs.package = nix-cachyos-kernel.zfs-cachyos;
}
```

### 3. 使用二进制缓存 (Binary Cache)

构建内核非常耗时。我通过 Hydra CI 构建内核并推送到 Attic 二进制缓存。

要使用缓存，请添加以下配置：

```nix
{
  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
}
```

或者使用 Garnix 缓存（如果有构建的话）：

```nix
{
  nix.settings.substituters = [ "https://cache.garnix.io" ];
  nix.settings.trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
}
```

## 常见问题

### 内核构建失败？

通常是因为 CachyOS 的补丁版本与 Nixpkgs 中的内核版本不匹配（例如上游已经到了 6.6.10，Nixpkgs 还在 6.6.9）。请等待一段时间，机器人会自动更新版本。

### ZFS 构建失败？

ZFS 对内核版本非常敏感。如果构建失败，通常是因为 CachyOS 尚未适配该内核版本的 ZFS 补丁。请耐心等待更新。

## 高级用法：自定义内核

你可以利用本项目的基础设施来构建自定义内核：

```nix
let
  # 假设你已经引入了 nix-cachyos-kernel
  customKernel = nix-cachyos-kernel.linux-cachyos-latest.override {
    pname = "my-custom-kernel";
    version = "6.12.34";
    # 覆盖源码
    src = pkgs.fetchurl { ... };
    # 更多可调参数请参考 kernel-cachyos/mkCachyKernel.nix
    lto = "full"; 
    configVariant = "linux-cachyos"; 
  };
in
# 获取对应的内核包集合
pkgs.linuxKernel.packagesFor customKernel
```
