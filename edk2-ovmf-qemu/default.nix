{
  stdenv,
  fetchFromGitHub,
  lib,
  acpica-tools,
  nasm,
  python3,
  pkgsCross,
  withSecureBoot ? true,
  withPlatforms ? {
    aarch64 = true;
    arm = true;
    ia32 = true;
    loongarch64 = true;
    riscv64 = true;
    x64 = true;
  },
}:

let
  withAarch64 = lib.attrByPath [ "aarch64" ] false withPlatforms;
  withArm = lib.attrByPath [ "arm" ] false withPlatforms;
  withIa32 = lib.attrByPath [ "ia32" ] false withPlatforms;
  withLoongarch64 = lib.attrByPath [ "loongarch64" ] false withPlatforms;
  withRiscv64 = lib.attrByPath [ "riscv64" ] false withPlatforms;
  withX64 = lib.attrByPath [ "x64" ] false withPlatforms;
in

assert withAarch64 || withArm || withIa32 || withLoongarch64 || withRiscv64 || withX64;

stdenv.mkDerivation (finalAttrs: {
  pname = "edk2-ovmf-qemu";
  version = "stable202505";

  src = fetchFromGitHub {
    owner = "tianocore";
    repo = "edk2";
    rev = "refs/tags/edk2-${finalAttrs.version}";
    hash = "sha256-VuiEqVpG/k7pfy0cOC6XmY+8NBtU/OHdDB9Y52tyNe8=";
    fetchSubmodules = true;
  };

  nativeBuildInputs =
    lib.optionals withAarch64 [
      pkgsCross.aarch64-embedded.buildPackages.gcc
    ]
    ++ lib.optionals withArm [
      pkgsCross.arm-embedded.buildPackages.gcc
    ]
    ++ lib.optionals withLoongarch64 [
      pkgsCross.loongarch64-linux.buildPackages.gcc
    ]
    ++ lib.optionals withRiscv64 [
      pkgsCross.riscv64-embedded.buildPackages.gcc
    ]
    ++ lib.optionals (withIa32 || withX64) [
      pkgsCross.x86_64-embedded.buildPackages.gcc
    ]
    ++ [
      acpica-tools
      nasm
      python3
    ];

  hardeningDisable = [
    "format"
    "relro"
  ];
  dontPatchELF = true;

  buildPhase =
    ''
      make -C BaseTools -j$NIX_BUILD_CORES
      set --
      source edksetup.sh
      build_aarch64 () {
        GCC5_AARCH64_PREFIX=aarch64-none-elf- \
        build -a AARCH64 -t GCC5 -b RELEASE -p ArmVirtPkg/ArmVirtQemu.dsc \
          -DSECURE_BOOT_ENABLE=$1 \
          -DTPM2_ENABLE=TRUE \
          -DTPM2_CONFIG_ENABLE=TRUE \
          -DNETWORK_TLS_ENABLE=TRUE \
          -DNETWORK_IP6_ENABLE=TRUE \
          -DNETWORK_HTTP_BOOT_ENABLE=TRUE
        [ -z "$2" ] || (
          cd Build/ArmVirtQemu-AARCH64/RELEASE_GCC5/FV
          mv QEMU_EFI.fd QEMU_EFI$2.fd
          mv QEMU_VARS.fd QEMU_VARS$2.fd
        )
      }
      build_arm () {
        GCC5_ARM_PREFIX=arm-none-eabi- \
        build -a ARM -t GCC5 -b RELEASE -p ArmVirtPkg/ArmVirtQemu.dsc \
          -DSECURE_BOOT_ENABLE=$1 \
          -DTPM2_ENABLE=TRUE \
          -DTPM2_CONFIG_ENABLE=TRUE \
          -DNETWORK_IP6_ENABLE=TRUE \
          -DNETWORK_HTTP_BOOT_ENABLE=TRUE
        [ -z "$2" ] || (
          cd Build/ArmVirtQemu-ARM/RELEASE_GCC5/FV
          mv QEMU_EFI.fd QEMU_EFI$2.fd
          mv QEMU_VARS.fd QEMU_VARS$2.fd
        )
      }
      build_loongarch64 () {
        GCC5_LOONGARCH64_PREFIX=loongarch64-unknown-linux-gnu- \
        build -a LOONGARCH64 -t GCC5 -b RELEASE \
          -p OvmfPkg/LoongArchVirt/LoongArchVirtQemu.dsc \
          -DSECURE_BOOT_ENABLE=$1 \
          -DTPM2_ENABLE=TRUE \
          -DTPM2_CONFIG_ENABLE=TRUE \
          -DNETWORK_IP6_ENABLE=TRUE \
          -DNETWORK_HTTP_BOOT_ENABLE=TRUE \
          -DNETWORK_TLS_ENABLE=TRUE
        [ -z "$2" ] || (
          cd Build/LoongArchVirtQemu/RELEASE_GCC5/FV
          mv QEMU_EFI.fd QEMU_EFI$2.fd
          mv QEMU_VARS.fd QEMU_VARS$2.fd
        )
      }
      build_riscv64 () {
        GCC5_RISCV64_PREFIX=riscv64-none-elf- \
        build -a RISCV64 -t GCC5 -b RELEASE \
          -p OvmfPkg/RiscVVirt/RiscVVirtQemu.dsc \
          -DSECURE_BOOT_ENABLE=$1 \
          -DTPM2_ENABLE=TRUE \
          -DTPM2_CONFIG_ENABLE=TRUE \
          -DNETWORK_IP6_ENABLE=TRUE \
          -DNETWORK_HTTP_BOOT_ENABLE=TRUE \
          -DNETWORK_TLS_ENABLE=TRUE
        [ -z "$2" ] || (
          cd Build/RiscVVirtQemu/RELEASE_GCC5/FV
          mv RISCV_VIRT_CODE.fd RISCV_VIRT_CODE$2.fd
          mv RISCV_VIRT_VARS.fd RISCV_VIRT_VARS$2.fd
        )
      }
      build_x64 () {
        GCC5_BIN=x86_64-elf- \
        build -a X64 -t GCC5 -b RELEASE -p OvmfPkg/OvmfPkgX64.dsc \
          -DFD_SIZE_4MB \
          -DSECURE_BOOT_ENABLE=$1 \
          -DTPM1_ENABLE=TRUE \
          -DTPM2_ENABLE=TRUE \
          -DTPM2_CONFIG_ENABLE=TRUE \
          -DSMM_REQUIRE=TRUE \
          -DNETWORK_TLS_ENABLE=TRUE \
          -DNETWORK_IP6_ENABLE=TRUE \
          -DNETWORK_HTTP_BOOT_ENABLE=TRUE
        [ -z "$2" ] || (
          cd Build/OvmfX64/RELEASE_GCC5/FV
          mv OVMF_CODE.fd OVMF_CODE$2.fd
          mv OVMF_VARS.fd OVMF_VARS$2.fd
        )
      }
      build_ia32 () {
        GCC5_BIN=x86_64-elf- \
        build -a IA32 -t GCC5 -b RELEASE -p OvmfPkg/OvmfPkgIa32.dsc \
          -DFD_SIZE_4MB \
          -DSECURE_BOOT_ENABLE=$1 \
          -DTPM1_ENABLE=TRUE \
          -DTPM2_ENABLE=TRUE \
          -DTPM2_CONFIG_ENABLE=TRUE \
          -DSMM_REQUIRE=TRUE \
          -DNETWORK_TLS_ENABLE=TRUE \
          -DNETWORK_IP6_ENABLE=TRUE \
          -DNETWORK_HTTP_BOOT_ENABLE=TRUE
        [ -z "$2" ] || (
          cd Build/OvmfIa32/RELEASE_GCC5/FV
          mv OVMF_CODE.fd OVMF_CODE$2.fd
          mv OVMF_VARS.fd OVMF_VARS$2.fd
        )
      }
    ''
    + lib.optionalString (withAarch64 && withSecureBoot) ''
      build_aarch64 TRUE .secure
    ''
    + lib.optionalString withAarch64 ''
      build_aarch64 FALSE
    ''
    + lib.optionalString (withArm && withSecureBoot) ''
      build_arm TRUE .secure
    ''
    + lib.optionalString withArm ''
      build_arm FALSE
    ''
    + lib.optionalString (withLoongarch64 && withSecureBoot) ''
      build_loongarch64 TRUE .secure
    ''
    + lib.optionalString withLoongarch64 ''
      build_loongarch64 FALSE
    ''
    + lib.optionalString (withRiscv64 && withSecureBoot) ''
      build_riscv64 TRUE .secure
    ''
    + lib.optionalString withRiscv64 ''
      build_riscv64 FALSE
    ''
    + lib.optionalString (withX64 && withSecureBoot) ''
      build_x64 TRUE .secure
    ''
    + lib.optionalString withX64 ''
      build_x64 FALSE
    ''
    + lib.optionalString (withIa32 && withSecureBoot) ''
      build_ia32 TRUE .secure
    ''
    + lib.optionalString withIa32 ''
      build_ia32 FALSE
    '';

  installPhase =
    ''
      mkdir -p $out/share/edk2-ovmf-qemu
      tar -cf - \
    ''
    + lib.optionalString withAarch64 ''
      Build/ArmVirtQemu-AARCH64/RELEASE_GCC5/FV/QEMU_*.fd \
    ''
    + lib.optionalString withArm ''
      Build/ArmVirtQemu-ARM/RELEASE_GCC5/FV/QEMU_*.fd \
    ''
    + lib.optionalString withLoongarch64 ''
      Build/LoongArchVirtQemu/RELEASE_GCC5/FV/QEMU_*.fd \
    ''
    + lib.optionalString withRiscv64 ''
      Build/RiscVVirtQemu/RELEASE_GCC5/FV/RISCV_VIRT_*.fd \
    ''
    + lib.optionalString withX64 ''
      Build/OvmfX64/RELEASE_GCC5/FV/OVMF_*.fd \
    ''
    + lib.optionalString withIa32 ''
      Build/OvmfIa32/RELEASE_GCC5/FV/OVMF_*.fd \
    ''
    + ''
      | tar -C $out/share/edk2-ovmf-qemu --strip-components=1 -xf -
    '';

  meta = {
    description = "UEFI firmware for QEMU";
    homepage = "https://github.com/tianocore/tianocore.github.io/wiki/OVMF";
    license = with lib.licenses; [
      bsd2Patent
      mit
      openssl
    ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
