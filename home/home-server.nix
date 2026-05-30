{ pkgs, ... }:

{
  imports = [
    ./core.nix
  ];

  home.packages = with pkgs; [
    inxi
    pciutils
    hwinfo
  ];
}
