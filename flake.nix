{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      support = _: pkgs: with pkgs.hostPlatform; isLinux || isDarwin;
      systems = lib.attrNames (lib.filterAttrs support nixpkgs.legacyPackages);
      pkgs = system: import ./. { pkgs = nixpkgs.legacyPackages.${system}; };
      packages = lib.genAttrs systems pkgs;
      addDefault = k: packages: packages // { default = packages.${k}; };
    in
    {
      packages = lib.mapAttrs (_: addDefault "edk2-ovmf-qemu") packages;
      overlays = {
        packages = final: prev: pkgs final.system;
      };
    };
}
