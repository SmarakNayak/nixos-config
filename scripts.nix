{ config, pkgs, lib, ... }:

let
  gamescope-m32q = pkgs.writeScriptBin "gamescope-m32q" ''
    #!/usr/bin/env bash
    # Gamescope wrapper optimized for Gigabyte M32Q (2560x1440@165Hz)
    # Usage in Steam launch options: gamescope-m32q %command%

    export MANGOHUD_CONFIG="no_display=1,refresh_rate"
    exec ${pkgs.gamescope}/bin/gamescope -w 2560 -h 1440 -W 2560 -H 1440 --mangoapp --adaptive-sync -- "$@"
  '';
in
{
  home.packages = [
    gamescope-m32q
  ];
}
