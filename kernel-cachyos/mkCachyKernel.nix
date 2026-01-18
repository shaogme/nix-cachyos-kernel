{
  inputs,
  lib,
  callPackage,
  buildLinux,
  stdenv,
  kernelPatches,
  applyPatches,
  impureUseNativeOptimizations,
  ...
}:
# 这是一个构建函数，用于生成定制化的 CachyOS 内核。
# 它基于 Nixpkgs 的 buildLinux，但添加了大量 CachyOS 特有的补丁、配置和调优选项。
lib.makeOverridable (
  {
    pname,
    version,
    src,

    # 内核配置变体，用作 defconfig 的基础。例如："linux-cachyos-lts"。
    # 可用的值请参考 https://github.com/CachyOS/linux-cachyos
    configVariant,

    # 设置 LTO (Link Time Optimization) 选项。
    # 可选值："none" (不使用 LTO), "thin" (ThinLTO), "full" (FullLTO)。
    # 除 "none" 外的任何值都会使用 Clang 来构建内核。
    lto ? "none",

    # 在 patchedSrc 阶段应用的补丁。这与 buildLinux 的 kernelPatches 不同。
    # 这些包括 prePatch 脚本, patches 列表, 和 postPatch 脚本。
    prePatch ? "",
    patches ? [ ],
    postPatch ? "",

    # CachyOS 的微调设置，对应的选项定义在 ./cachySettings.nix 中。
    # 默认值参考自 https://github.com/CachyOS/linux-cachyos/blob/master/linux-cachyos/PKGBUILD
    # 将选项设置为 null 或 false 可以禁用对应的调优。
    
    # CPU 调度器选择，默认为 "bore"
    cpusched ? "bore",
    # 是否启用内核控制流完整性 (Kernel Control Flow Integrity)
    kcfi ? false,
    # 内核时钟频率 (HZ)，默认为 1000Hz
    hzTicks ? "1000",
    # 是否启用性能调频器 (Performance Governor)
    performanceGovernor ? false,
    # 时钟滴答率设置 (Tick Rate)，默认为 "full" (NO_HZ_FULL)
    tickrate ? "full",
    # 抢占模式 (Preemption Model)，默认为 "full" (Fully Preemptible Kernel)
    preemptType ? "full",
    # 是否启用更激进的编译器优化 (-O3)
    ccHarder ? true,
    # 是否启用 BBRv3 TCP 拥塞控制算法
    bbr3 ? false,
    # 透明大页 (Transparent Hugepages) 设置，默认为 "always"
    hugepage ? "always",
    # 处理器架构优化级别，例如 "x86_64-v1", "zen4" 等
    processorOpt ? "x86_64-v1",

    # CachyOS 额外的补丁设置开关
    # 是否启用加固补丁 (Hardened)
    hardened ? false,
    # 是否启用实时补丁 (Real-time)
    rt ? false,
    # 是否启用 acpi_call 模块支持
    acpiCall ? false,
    # 是否启用掌机优化补丁 (Handheld)
    handheld ? false,

    # AutoFDO settings
    # AutoFDO hasn't been fully tested. Please report issue if you encounter any.
    #
    # false - Disable AutoFDO
    # true - Enable AutoFDO for profiling performance patterns only
    # ./path/to/autofdo/profile: Enable AutoFDO with specified profile
    autofdo ? false,

    # 尽可能将组件构建为内核模块，即使是通常禁用的组件。
    # 这可能会启用一些意外的模块，例如 nova_core。
    # 参见: https://github.com/xddxdd/nix-cachyos-kernel/issues/13
    #
    # 禁用此选项曾导致启动问题，因此默认重新启用。
    autoModules ? true,

    # 其他参数将传递给 buildLinux。
    # 更多选项请参考 nixpkgs/pkgs/os-specific/linux/kernel/generic.nix。
    ...
  }@args:

  # AutoFDO requires Clang compiler
  assert autofdo != false -> lto != "none";

  let
    # 引入辅助函数
    helpers = callPackage ../helpers.nix { };
    inherit (helpers) stdenvLLVM ltoMakeflags;

    # 用于查找对应版本的补丁目录 (取主版本号和次版本号)
    patchVersion = lib.versions.majorMinor version;

    # 用于 moddirversion (补全版本号至 3 位)
    fullVersion = lib.versions.pad 3 version;

    # CachyOS 的配置文件路径
    cachyosConfigFile = "${inputs.cachyos-kernel}/${configVariant}/config";
    
    # 构建需要应用的 CachyOS 补丁列表
    cachyosPatches = builtins.map (p: "${inputs.cachyos-kernel-patches}/${patchVersion}/${p}") (
      [ "all/0001-cachyos-base-all.patch" ]
      # 根据 cpusched 参数添加特定的调度器补丁
      ++ (lib.optional (cpusched == "bore") "sched/0001-bore-cachy.patch")
      ++ (lib.optional (cpusched == "bmq") "sched/0001-prjc-cachy.patch")
      # 根据开关添加其他功能补丁
      ++ (lib.optional hardened "misc/0001-hardened.patch")
      ++ (lib.optional rt "misc/0001-rt-i915.patch")
      ++ (lib.optional acpiCall "misc/0001-acpi-call.patch")
      ++ (lib.optional handheld "misc/0001-handheld.patch")
    );

    # buildLinux 不直接支持 postPatch 参数，所以我们在这里预先定义 source 阶段。
    # 我们创建一个应用了补丁的源码目录。
    patchedSrc = applyPatches {
      name = "linux-src-patched";
      inherit src;
      patches = [
        # NixOS 必须的一些基础补丁
        kernelPatches.bridge_stp_helper.patch
        kernelPatches.request_key_helper.patch
      ]
      # 添加 CachyOS 补丁
      ++ cachyosPatches
      # 添加用户自定义补丁
      ++ patches;
      
      # 在补丁应用后执行的 shell 命令
      postPatch = ''
        # 将 CachyOS 的配置文件安装到内核源码树的默认配置位置
        install -Dm644 ${cachyosConfigFile} arch/x86/configs/cachyos_defconfig
      ''
      + postPatch;
    };

    # 定义默认的本地版本后缀
    # 如果不使用 LTO，后缀为 "-cachyos"；如果使用 LTO，则为 "-cachyos-lto"
    defaultLocalVersion = if lto == "none" then "-cachyos" else "-cachyos-lto";

    # 导入 CachyOS 设置定义
    cachySettings = callPackage ./cachySettings.nix { };
    
    # 结构化的内核配置 (Structured Config)
    structuredExtraConfig =
      # 应用基础的内核选项
      (with lib.kernel; {
        # 设置最大 CPU 数量
        NR_CPUS = lib.mkForce (option (freeform "512"));

        # 设置本地版本后缀
        LOCALVERSION = freeform defaultLocalVersion;

        # 跟随 NixOS 默认配置，避免破坏 etc overlay
        # 禁用 OverlayFS 的一些可能会导致问题的特性
        OVERLAY_FS = module;
        OVERLAY_FS_REDIRECT_DIR = no;
        OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW = yes;
        OVERLAY_FS_INDEX = no;
        OVERLAY_FS_XINO_AUTO = no;
        OVERLAY_FS_METACOPY = no;
        OVERLAY_FS_DEBUG = no;
      })

      # 应用 CachyOS 特有的设置
      # 使用 lib.mkForce 强制应用这些设置，覆盖默认值
      // (lib.mapAttrs (_: lib.mkForce) (
        cachySettings.common
        # 根据 LTO 选项应用对应的设置
        // (cachySettings.lto."${lto}")
        # 根据 cpusched 选项应用对应的调度器设置
        // (lib.optionalAttrs (cpusched != null) cachySettings.cpusched."${cpusched}")
        # 启用 KCFI 设置
        // (lib.optionalAttrs kcfi cachySettings.kcfi)
        # 设置时钟频率
        // (lib.optionalAttrs (hzTicks != null) cachySettings.hzTicks."${hzTicks}")
        # 设置性能调频器
        // (lib.optionalAttrs performanceGovernor cachySettings.performanceGovernor)
        # 设置 Tick Rate (NO_HZ 设置)
        // (lib.optionalAttrs (tickrate != null) cachySettings.tickrate."${tickrate}")
        # 设置抢占模式
        // (lib.optionalAttrs (preemptType != null) cachySettings.preemptType."${preemptType}")
        # 更激进的编译优化
        // (lib.optionalAttrs ccHarder cachySettings.ccHarder)
        # BBRv3 设置
        // (lib.optionalAttrs bbr3 cachySettings.bbr3)
        # 大页设置
        // (lib.optionalAttrs (hugepage != null) cachySettings.hugepage."${hugepage}")
        # 处理器架构优化设置
        // (lib.optionalAttrs (processorOpt != null) cachySettings.processorOpt.${processorOpt})
        // (lib.optionalAttrs (autofdo != false) {
          AUTOFDO_CLANG = lib.kernel.yes;
        })
      ))

      # 应用用户通过参数传入的额外配置
      // (args.structuredExtraConfig or { });
  in
  buildLinux (
    # 从参数中移除 mkCachyKernel 特有的参数，剩下的传递给 buildLinux
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

      stdenv =
        # Apply native optimization on top of stdenv if requested
        (if processorOpt == "native" then impureUseNativeOptimizations else lib.id)
          # Select stdenv/stdenvLLVM based on requested compiler
          (args.stdenv or (if lto == "none" then stdenv else stdenvLLVM));

      extraMakeFlags =
        (lib.optionals (lto != "none") ltoMakeflags)
        ++ lib.optionals (builtins.isPath autofdo) [
          "CLANG_AUTOFDO_PROFILE=${autofdo}"
        ]
        ++ (args.extraMakeFlags or [ ]);

      # 指定 defconfig 文件名
      defconfig = args.defconfig or "cachyos_defconfig";

      # 指定模块目录版本
      modDirVersion = args.modDirVersion or "${fullVersion}${defaultLocalVersion}";

      # CachyOS 的配置可能包含一些旧内核版本不再使用的选项，忽略配置错误
      ignoreConfigErrors = args.ignoreConfigErrors or true;

      inherit structuredExtraConfig autoModules;

      extraMeta = {
        description =
          "Linux CachyOS Kernel"
          + lib.optionalString (lto == "thin") " with Clang+ThinLTO"
          + lib.optionalString (lto == "full") " with Clang+FullLTO";
        # 目前仅支持 x86_64
        broken = !stdenv.isx86_64;
      }
      // (args.extraMeta or { });

      extraPassthru = {
        # 暴露配置文件和补丁列表供外部使用
        inherit cachyosConfigFile cachyosPatches;
      }
      // (args.extraPassthru or { });
    }
  )
)
