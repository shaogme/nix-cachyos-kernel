{
  inputs,
  callPackage,
  lib,
  linux_latest,
  linux_testing,
  linux,
  ...
}:
let
  # 导入构建 CachyOS 内核的函数 mkCachyKernel
  mkCachyKernel = callPackage ./mkCachyKernel.nix { inherit inputs; };
in
# 使用 builtins.listToAttrs 将生成的内核列表转换为属性集 (AttrSet)
# 键为内核的 pname (例如 "linux-cachyos-latest")，值为对应的 derivation
builtins.listToAttrs (
  builtins.map (v: lib.nameValuePair v.pname v) [
    # ==========================================
    # 最新版内核 (Latest Kernel)
    # 基于 Nixpkgs 的 linux_latest (当前最新稳定版)
    # 提供各种 LTO 和 CPU 架构优化的变体
    # ==========================================

    # 1. 基础版本 (Standard)
    (mkCachyKernel {
      pname = "linux-cachyos-latest";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
    })

    # 2. CPU 架构优化版本 (Microarchitecture Optimized)
    # 针对特定的 x86-64 微架构级别进行优化，可提升性能
    
    # x86-64-v2 (例如: Sandy Bridge, Haswell 等较旧的 CPU)
    (mkCachyKernel {
      pname = "linux-cachyos-latest-x86_64-v2";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      processorOpt = "x86_64-v2";
    })
    # x86-64-v3 (例如: Haswell, Skylake, Zen 等现代主流 CPU)
    (mkCachyKernel {
      pname = "linux-cachyos-latest-x86_64-v3";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      processorOpt = "x86_64-v3";
    })
    # x86-64-v4 (例如: Sapphire Rapids, Zen 4, Zen 5 等支持 AVX-512 的最新 CPU)
    (mkCachyKernel {
      pname = "linux-cachyos-latest-x86_64-v4";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      processorOpt = "x86_64-v4";
    })
    # Zen 4 架构特定优化
    (mkCachyKernel {
      pname = "linux-cachyos-latest-zen4";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      processorOpt = "zen4";
    })

    # 3. LTO (Link Time Optimization) 版本
    # 使用 Clang ThinLTO 构建，通常能带来更好的性能
    
    # 基础 LTO 版本
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
    })
    # LTO + x86-64-v2
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-x86_64-v2";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "x86_64-v2";
    })
    # LTO + x86-64-v3
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-x86_64-v3";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "x86_64-v3";
    })
    # LTO + x86-64-v4
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-x86_64-v4";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "x86_64-v4";
    })
    # LTO + Zen 4
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-zen4";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "zen4";
    })

    # ==========================================
    # 长期支持版内核 (LTS Kernel)
    # 基于 Nixpkgs 的 linux (当前 LTS 版本)
    # ==========================================
    
    # 基础 LTS 版本
    (mkCachyKernel {
      pname = "linux-cachyos-lts";
      inherit (linux) version src;
      configVariant = "linux-cachyos-lts";
    })
    # LTO 优化的 LTS 版本
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto";
      inherit (linux) version src;
      configVariant = "linux-cachyos-lts";
      lto = "thin";
    })

    # ==========================================
    # 其他 CachyOS 特性变体 (Additional Variants)
    # 包含不同的调度器、实时补丁、服务器优化等
    # ==========================================

    # BMQ (BitMap Queue) 调度器版本
    (mkCachyKernel {
      pname = "linux-cachyos-bmq";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-bmq";
      cpusched = "bmq";
    })
    # BMQ + LTO
    (mkCachyKernel {
      pname = "linux-cachyos-bmq-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-bmq";
      lto = "thin";
      cpusched = "bmq";
    })

    # BORE (Burst-Oriented Response Enhancer) 调度器版本 (默认 CachyOS 调度器)
    (mkCachyKernel {
      pname = "linux-cachyos-bore";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-bore";
      cpusched = "bore";
    })
    # BORE + LTO
    (mkCachyKernel {
      pname = "linux-cachyos-bore-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-bore";
      lto = "thin";
      cpusched = "bore";
    })

    # Deckify 版本 (Steam Deck / 掌机优化)
    # 包含 acpi_call 和 handheld 补丁以支持特定的掌机硬件控制
    (mkCachyKernel {
      pname = "linux-cachyos-deckify";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-deckify";
      acpiCall = true;
      handheld = true;
    })
    # Deckify + LTO
    (mkCachyKernel {
      pname = "linux-cachyos-deckify-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-deckify";
      lto = "thin";
      acpiCall = true;
      handheld = true;
    })

    # EEVDF (Earliest Eligible Virtual Deadline First) 调度器版本
    (mkCachyKernel {
      pname = "linux-cachyos-eevdf";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-eevdf";
      cpusched = "eevdf";
    })
    # EEVDF + LTO
    (mkCachyKernel {
      pname = "linux-cachyos-eevdf-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-eevdf";
      cpusched = "eevdf";
      lto = "thin";
    })

    # Hardened 版本 (安全加固)
    # 应用了额外的安全补丁
    (mkCachyKernel {
      pname = "linux-cachyos-hardened";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-hardened";
      hardened = true;
    })
    # Hardened + LTO
    (mkCachyKernel {
      pname = "linux-cachyos-hardened-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-hardened";
      hardened = true;
      lto = "thin";
    })

    # RC (Release Candidate) 测试版内核
    # 基于 linux_testing (上游的 -rc 版本)
    (mkCachyKernel {
      pname = "linux-cachyos-rc";
      inherit (linux_testing) version src;
      configVariant = "linux-cachyos-rc";
    })
    # RC + LTO
    (mkCachyKernel {
      pname = "linux-cachyos-rc-lto";
      inherit (linux_testing) version src;
      configVariant = "linux-cachyos-rc";
      lto = "thin";
    })

    # RT (Real-Time) 实时内核版本
    # 使用 BORE 调度器并启用了 PREEMPT_RT
    (mkCachyKernel {
      pname = "linux-cachyos-rt-bore";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-rt-bore";
      rt = true;
      cpusched = "bore";
    })
    # RT + LTO
    (mkCachyKernel {
      pname = "linux-cachyos-rt-bore-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-rt-bore";
      rt = true;
      cpusched = "bore";
      lto = "thin";
    })

    # Server 服务器优化版本
    # 使用 EEVDF 调度器，更低的 HZ 配置 (300Hz)，禁用抢占 (preemptType = "none")
    # 这种配置旨在最大化吞吐量而非响应性
    (mkCachyKernel {
      pname = "linux-cachyos-server";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-server";
      cpusched = "eevdf";
      hzTicks = "300";
      preemptType = "none";
    })
    # Server + LTO
    (mkCachyKernel {
      pname = "linux-cachyos-server-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-server";
      cpusched = "eevdf";
      hzTicks = "300";
      preemptType = "none";
      lto = "thin";
    })
  ]
)
