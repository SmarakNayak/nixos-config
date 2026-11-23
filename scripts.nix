{ config, pkgs, lib, ... }:

let
  gamescope-m32q = pkgs.writeScriptBin "gamescope-m32q" ''
    #!/usr/bin/env bash
    # Gamescope wrapper optimized for Gigabyte M32Q (2560x1440@165Hz)
    # Usage in Steam launch options: gamescope-m32q %command%

    export MANGOHUD_CONFIG="no_display=1,refresh_rate"
    exec ${pkgs.gamescope}/bin/gamescope -w 2560 -h 1440 -W 2560 -H 1440 --mangoapp --adaptive-sync --force-grab-cursor -- "$@"
  '';

  screenshot-ocr = pkgs.writeShellApplication {
    name = "screenshot-ocr";
    runtimeInputs = with pkgs; [
      grim
      slurp
      (tesseract.override { enableLanguages = [ "eng" ]; })
      wl-clipboard
      libnotify
    ];
    text = ''
      clipboard_types="$(wl-paste --list-types 2>/dev/null)" || clipboard_types=
      image_type=
      for mime_type in image/png image/jpeg image/webp image/tiff image/bmp image/gif; do
        if [[ $'\n'"$clipboard_types"$'\n' == *$'\n'"$mime_type"$'\n'* ]]; then
          image_type="$mime_type"
          break
        fi
      done

      if [[ -n "$image_type" ]]; then
        image_command=(wl-paste --no-newline --type "$image_type")
      else
        region="$(slurp)" || exit 0
        [[ -n "$region" ]] || exit 0
        image_command=(grim -g "$region" -)
      fi

      if ! text="$("''${image_command[@]}" | tesseract stdin stdout -l eng --psm 11 -c page_separator=)"; then
        notify-send "Screenshot OCR failed" "Could not read the image."
        exit 1
      fi

      if [[ ! "$text" =~ [^[:space:]] ]]; then
        notify-send "Screenshot OCR" "No text found."
        exit 0
      fi

      printf '%s' "$text" | wl-copy --type 'text/plain;charset=utf-8'
      notify-send "Screenshot OCR" "Text copied to clipboard."
    '';
  };
in
{
  home.packages = [
    gamescope-m32q
    screenshot-ocr
  ];
}
