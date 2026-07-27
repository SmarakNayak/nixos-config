{ pkgs, ... }:

{
  imports = [
    ./core.nix
  ];

  home.packages = with pkgs; [
    ghostty.terminfo
    inxi
    pciutils
    hwinfo
  ];
}
