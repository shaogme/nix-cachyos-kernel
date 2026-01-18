{ lib, ... }:
with lib.kernel;
# 此文件包含 CachyOS 内核的模块化配置片段。
# 这些配置主要参考自 CachyOS 的 PKGBUILD:
# https://github.com/CachyOS/linux-cachyos/blob/master/linux-cachyos/PKGBUILD
{
  # 通用设置，适用于所有 CachyOS 变体
  common = {
    # 标识这是一个 CachyOS 内核
    CACHY = yes;

    # 启用 Adios I/O 调度器
    # 详情: https://wiki.cachyos.org/configuration/general_system_tweaks/#adios-io-scheduler
    MQ_IOSCHED_ADIOS = yes;
  };

  # CPU 调度器配置
  cpusched = rec {
    # BORE (Burst-Oriented Response Enhancer) 调度器
    bore = {
      SCHED_BORE = yes;
    };
    # BMQ (BitMap Queue) 调度器 (Project C 的一部分)
    bmq = {
      SCHED_ALT = yes;
      SCHED_BMQ = yes;
    };
    # EEVDF (Earliest Eligible Virtual Deadline First) 调度器
    # Linux 6.6+ 的默认调度器，这里不需要额外配置，或者可能需要禁用其他调度器补丁
    eevdf = { };
    # 实时 (Real-Time) 调度
    rt = {
      PREEMPT_RT = yes;
    };
    # 实时内核 + BORE 调度器
    rt-bore = rt // bore;
  };

  # KCFI (Kernel Control Flow Integrity) 安全特性
  # 一种旨在防止利用控制流劫持漏洞的漏洞利用缓解机制
  kcfi = {
    ARCH_SUPPORTS_CFI_CLANG = yes;
    CFI_CLANG = yes;
    CFI_AUTO_DEFAULT = yes;
  };

  # 内核时钟频率 (HZ) 设置
  hzTicks = {
    # 300Hz: 适合服务器，吞吐量优先
    "300" = {
      HZ_300 = yes;
      HZ = freeform "300";
    };
  }
  # 使用 lib.genAttrs 生成其他常见频率的配置 (100, 250, 500, 600, 750, 1000)
  # 1000Hz: 适合桌面和游戏，低延迟优先
  // lib.genAttrs [ "100" "250" "500" "600" "750" "1000" ] (hz: {
    HZ_300 = no; # 需要确保禁用默认的 300Hz (如果是基于某些默认配置)
    "HZ_${hz}" = yes;
    HZ = freeform hz;
  });

  # LTO (Link Time Optimization) 链接时优化设置
  lto = {
    # 不启用 LTO
    none = {
      LTO_NONE = yes;
      LTO_CLANG_THIN = no;
      LTO_CLANG_FULL = no;
    };
    # ThinLTO: 编译速度和性能的平衡，CachyOS 默认推荐
    thin = {
      LTO_NONE = no;
      LTO_CLANG_THIN = yes;
      LTO_CLANG_FULL = no;
    };
    # FullLTO: 极致的优化，编译时间极长
    full = {
      LTO_NONE = no;
      LTO_CLANG_THIN = no;
      LTO_CLANG_FULL = yes;
    };
  };

  # CPU 频率调节器 (Governor) 设置
  performanceGovernor = {
    # 禁用 schedutil 作为默认
    CPU_FREQ_DEFAULT_GOV_SCHEDUTIL = no;
    # 启用 performance 作为默认，使 CPU 始终运行在最高频率，适合高性能需求
    CPU_FREQ_DEFAULT_GOV_PERFORMANCE = yes;
  };

  # 处理器微架构优化级别 (CPU Microarchitecture Optimization)
  # 通过针对特定 CPU 指令集进行编译来提升性能
  processorOpt = {
    # x86-64-v1: 基准指令集，兼容性最好
    x86_64-v1 = {
      GENERIC_CPU = yes;
      MZEN4 = no;
      X86_NATIVE_CPU = no;
      X86_64_VERSION = freeform "1";
    };
    # x86-64-v2: 增加了 SSE4.2, SSSE3, POPCNT 等指令
    x86_64-v2 = {
      GENERIC_CPU = yes;
      MZEN4 = no;
      X86_NATIVE_CPU = no;
      X86_64_VERSION = freeform "2";
    };
    # x86-64-v3: 增加了 AVX, AVX2, BMI1, BMI2, F16C, FMA 等指令 (Haswell+)
    x86_64-v3 = {
      GENERIC_CPU = yes;
      MZEN4 = no;
      X86_NATIVE_CPU = no;
      X86_64_VERSION = freeform "3";
    };
    # x86-64-v4: 增加了 AVX512 系列指令
    x86_64-v4 = {
      GENERIC_CPU = yes;
      MZEN4 = no;
      X86_NATIVE_CPU = no;
      X86_64_VERSION = freeform "4";
    };
    # Zen 4: 针对 AMD Zen 4 架构的特定优化
    zen4 = {
      GENERIC_CPU = no;
      MZEN4 = yes;
      X86_NATIVE_CPU = no;
    };
    native = {
      GENERIC_CPU = no;
      X86_NATIVE_CPU = yes;
    };
  };

  # 时钟滴答率 (Tick Rate) / NO_HZ 设置
  tickrate = {
    # 周期性滴答 (Periodic Timer): 时钟中断以固定频率发生
    periodic = {
      NO_HZ_IDLE = no;
      NO_HZ_FULL = no;
      NO_HZ = no;
      NO_HZ_COMMON = no;
      HZ_PERIODIC = yes;
    };
    # 空闲时无滴答 (Tickless Idle): CPU 空闲时停止时钟中断 (最常用)
    idle = {
      HZ_PERIODIC = no;
      NO_HZ_FULL = no;
      NO_HZ_IDLE = yes;
      NO_HZ = yes;
      NO_HZ_COMMON = yes;
    };
    # 完全无滴答 (Full Tickless): 即使 CPU 在运行任务也尽量减少时钟中断
    # 适合实时应用和高性能计算
    full = {
      HZ_PERIODIC = no;
      NO_HZ_IDLE = no;
      CONTEXT_TRACKING_FORCE = no;
      NO_HZ_FULL_NODEF = yes;
      NO_HZ_FULL = yes;
      NO_HZ = yes;
      NO_HZ_COMMON = yes;
      CONTEXT_TRACKING = yes;
    };
  };

  # 内核抢占模式 (Preemption Model)
  preemptType = {
    # 完全抢占 (Fully Preemptible Kernel): 适合桌面和低延迟场景
    full = {
      PREEMPT_DYNAMIC = yes;
      PREEMPT = yes;
      PREEMPT_VOLUNTARY = no;
      PREEMPT_LAZY = no;
      PREEMPT_NONE = no;
    };
    # 懒惰抢占 (Lazy Preemption): 一种新的抢占模式，试图在吞吐量和延迟之间取得平衡
    lazy = {
      PREEMPT_DYNAMIC = yes;
      PREEMPT = no;
      PREEMPT_VOLUNTARY = no;
      PREEMPT_LAZY = yes;
      PREEMPT_NONE = no;
    };
    # 自愿抢占 (Voluntary Preemption): 适合桌面，吞吐量比 Full 高
    voluntary = {
      PREEMPT_DYNAMIC = no;
      PREEMPT = no;
      PREEMPT_VOLUNTARY = yes;
      PREEMPT_LAZY = no;
      PREEMPT_NONE = no;
    };
    # 不抢占 (No Preemption): 适合服务器，最大化吞吐量
    none = {
      PREEMPT_DYNAMIC = no;
      PREEMPT = no;
      PREEMPT_VOLUNTARY = no;
      PREEMPT_LAZY = no;
      PREEMPT_NONE = yes;
    };
  };

  # 编译器优化设置
  ccHarder = {
    CC_OPTIMIZE_FOR_PERFORMANCE = no;
    # 强制启用 -O3 优化等级
    CC_OPTIMIZE_FOR_PERFORMANCE_O3 = yes;
  };

  # BBRv3 TCP 拥塞控制
  bbr3 = {
    TCP_CONG_CUBIC = module;
    DEFAULT_CUBIC = no;
    # 启用 BBR
    TCP_CONG_BBR = yes;
    # 设为默认拥塞控制算法
    DEFAULT_BBR = yes;
    DEFAULT_TCP_CONG = freeform "bbr";
    # 配合 BBR 通常需要 FQ (Fair Queueing) 调度
    NET_SCH_FQ_CODEL = module;
    NET_SCH_FQ = yes;
    CONFIG_DEFAULT_FQ_CODEL = no;
    CONFIG_DEFAULT_FQ = yes;
  };

  # 透明大页 (Transparent Hugepages) 设置
  hugepage = {
    # 总是使用 THP (可能会增加内存开销，但提升性能)
    always = {
      TRANSPARENT_HUGEPAGE_MADVISE = no;
      TRANSPARENT_HUGEPAGE_ALWAYS = yes;
    };
    # 仅在应用程序请求时使用 (madvise)
    madvise = {
      TRANSPARENT_HUGEPAGE_ALWAYS = no;
      TRANSPARENT_HUGEPAGE_MADVISE = yes;
    };
  };
}
