{ pkgs, ... }:

let
  hermes-sandbox = import ../packages/hermes-sandbox.nix { inherit pkgs; };
in

{
  imports = [
    ./core.nix
  ];

  home.packages = with pkgs; [
    hermes-sandbox
    inxi
    pciutils
    hwinfo
  ];
}
