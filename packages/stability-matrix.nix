{ pkgs, ... }:

let
  appimage-run = pkgs.appimage-run.override {
    extraPkgs = pkgs: [
      pkgs.icu
      pkgs.libxcrypt-legacy
      pkgs.uv
    ];
  };

  src = pkgs.fetchzip {
    url = "https://github.com/LykosAI/StabilityMatrix/releases/download/v2.15.6/StabilityMatrix-linux-x64.zip";
    hash = "sha256-607+rH7jURBpA7AW/jIuW9WHz7x20JxWT+MGSx/MAuU=";
    stripRoot = false;
  };
in
pkgs.writeShellScriptBin "stability-matrix" ''
  exec ${appimage-run}/bin/appimage-run ${src}/StabilityMatrix.AppImage "$@"
''
