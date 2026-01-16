{
  inputs,
  callPackage,
  lib,
  linuxKernel,
  ...
}:
let
  # 导入辅助函数
  helpers = callPackage ../helpers.nix { };
  # 继承 kernelModuleLLVMOverride 函数，用于修复使用 Clang/LLVM 构建的内核模块
  inherit (helpers) kernelModuleLLVMOverride;

  # 获取 default.nix 中定义的所有内核 derivation
  # 使用 lib.filterAttrs 过滤出有效的 derivation (排除非 derivation 的属性)
  kernels = lib.filterAttrs (_: lib.isDerivation) (callPackage ./. { inherit inputs; });
in
# 使用 lib.mapAttrs' 遍历所有内核，为每个内核生成对应的 linuxPackages
lib.mapAttrs' (
  n: v:
  let
    # 为当前内核 (v) 生成内核模块包集合 (linuxPackages)
    packages = kernelModuleLLVMOverride (
      # linuxKernel.packagesFor 是 Nixpkgs 提供的函数，用于为指定内核生成包集合
      (linuxKernel.packagesFor v).extend (
        # 使用 extend 扩展包集合，添加自定义的内核模块
        final: prev: {
          # 添加 ZFS 模块，针对 CachyOS 内核进行构建
          zfs_cachyos = final.callPackage ../zfs-cachyos {
            inherit inputs;
          };
        }
      )
    );
  in
  # 重命名属性名：将 "linux-cachyos-..." 映射为 "linuxPackages-cachyos-..."
  # 例如: "linux-cachyos-latest" -> "linuxPackages-cachyos-latest"
  # lib.removePrefix "linux-" n 用于去掉原名的 "linux-" 前缀
  lib.nameValuePair "linuxPackages-${lib.removePrefix "linux-" n}" packages
) kernels
