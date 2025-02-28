# Nix package of EDK2 OVMF UEFI firmware for QEMU

This respository provides `edk2-ovmf-qemu` package that contains
UEFI firmware for QEMU on arm32/64, loongaarch64, riscv64, and x86_32/64.

Unlike `nixpkgs#OVMF`, this compiles the firmware by using cross compiler.
This allows us to build any firmware on any host platform.

## Overrides

You can specify which firmwares to be built through `override`.
Possible attributes are the following:

- `withSecureBoot` (Bool): build SecureBoot-enabled versions (default: true)
- `withPlatforms` (AttrSet): build firmwares only for specified platforms (default: all).
  This must be an attrset that maps the following to Bool:
  - `aarch64`
  - `arm`
  - `loongarch64`
  - `riscv64`
  - `ia32`
  - `x64`
  Omission means `false`.
  At least one firmware must be built.

For example, if you need only x64 without secure boot, use the following:

```nix
  edk2-ovmf-qemu.override ({
    withSecureBoot = false;
    withPlatforms = { x64 = true; };
  })
```

## Flakes

Include the following in your `flake.nix`:

```nix
{
  inputs.ovmf.url = "github:uenob/edk2-ovmf-qemu";
}
```

If you want to build firmwares with the latest cross compilers,
override nixpkgs of this repo as follows:

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.ovmf.url = "github:uenob/edk2-ovmf-qemu";
  inputs.ovmf.inputs.nixpkgs.follows = "nixpkgs";
}
```

## License

MIT
