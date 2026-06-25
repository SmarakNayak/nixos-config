{ pkgs, ... }:

let
  # GIO reads the desktop-file MIME database, so this sees apps that advertise
  # support even when no user association is set.
  yazi-open-with = pkgs.writeShellApplication {
    name = "yazi-open-with";
    runtimeInputs = with pkgs; [
      fuzzel
      glib
    ];
    text = ''
      file=''${1:-}
      [[ -n "$file" ]] || exit 0

      mime=
      while IFS= read -r line; do
        [[ "$line" == *"standard::content-type:"* ]] && mime=''${line##*: }
      done < <(gio info -a standard::content-type "$file")
      [[ -n "$mime" ]] || exit 0

      desktop_path() {
        local dir path
        local IFS=:
        for dir in ''${XDG_DATA_HOME:-$HOME/.local/share}:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do
          path="$dir/applications/$1"
          if [[ -f "$path" ]]; then
            printf '%s\n' "$path"
            return 0
          fi
        done
        return 1
      }

      desktop_key() {
        local line
        while IFS= read -r line; do
          if [[ "$line" == "$1="* ]]; then
            printf '%s\n' "''${line#*=}"
            return 0
          fi
        done < "$2"
      }

      applications() {
        local in_apps=0 line id path name icon
        declare -A seen=()

        while IFS= read -r line; do
          case "$line" in
            "Recommended applications:" | "Registered applications:")
              in_apps=1
              continue
              ;;
            [![:space:]]*)
              in_apps=0
              ;;
          esac

          (( in_apps )) || continue

          id=''${line#"''${line%%[![:space:]]*}"}
          [[ -n "$id" && ! -v "seen[$id]" ]] || continue
          seen[$id]=1

          path=$(desktop_path "$id") || continue
          name=$(desktop_key Name "$path")
          icon=$(desktop_key Icon "$path")

          [[ -n "$name" ]] || name=''${id%.desktop}

          if [[ -n "$icon" ]]; then
            printf '%s\t%s\0icon\x1f%s\n' "$path" "$name" "$icon"
          else
            printf '%s\t%s\n' "$path" "$name"
          fi
        done < <(gio mime "$mime")
      }

      app=$(
        applications \
        | fuzzel --dmenu --prompt="Open With: " \
            --with-nth=2 \
            --accept-nth=1 \
            --match-nth=2 \
            --no-run-if-empty
      ) || exit 0

      [[ -n "$app" ]] || exit 0

      if [[ "$(desktop_key Terminal "$app")" == true ]]; then
        eval "set -- $(desktop_key Exec "$app")"

        args=()
        replaced=0
        for arg do
          case "$arg" in
            %f | %F | %u | %U)
              args+=("$file")
              replaced=1
              ;;
            %i | %c | %k)
              ;;
            *)
              args+=("$arg")
              ;;
          esac
        done

        (( replaced )) || args+=("$file")
        "''${TERMINAL:-ghostty}" -e "''${args[@]}" >/dev/null 2>&1 &
      else
        gio launch "$app" "$file" >/dev/null 2>&1 &
      fi
    '';
  };
in
{
  home.packages = [
    yazi-open-with
  ];
}
