{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      support = _: pkgs: with pkgs.hostPlatform; isLinux || isDarwin;
      systems = lib.attrNames (lib.filterAttrs support nixpkgs.legacyPackages);
    in
    rec {
      packages = lib.genAttrs systems (
        system:
        let
          packages = import ./. { pkgs = nixpkgs.legacyPackages.${system}; };
        in
        packages // { default = packages.edk2-ovmf-qemu; }
      );
      overlays = {
        packages = final: prev: import ./. { pkgs = final; };
      };
    };
}
