{
  pkgs ? import <nixpkgs> { },
}:

{
  edk2-ovmf-qemu = pkgs.callPackage ./edk2-ovmf-qemu { };
}
