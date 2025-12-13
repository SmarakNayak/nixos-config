{ config, pkgs, lib, nix-ai-tools, ... }:

let
  claude-distro = import ./distrobox-packages/claude-code.nix { inherit pkgs; };
in
{
  imports = [
    ./scripts.nix
  ];

  home.username = "miltu";
  home.homeDirectory = "/home/miltu";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    curl
    distrobox
    claude-distro
    claude-code
    nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.gemini-cli
    speedtest-go
    networkmanagerapplet
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    # CLI tools without home-manager modules
    procs
    sd
    wl-clipboard
    neofetch
    ollama
    unzip
    # GUI applications
    ghostty
    wofi
    waybar
    google-chrome
    pavucontrol
    blueman
    mission-center
    signal-desktop
    discord
    wasistlos
    tree
    # Gaming
    gamescope
    mangohud
    heroic
    # Media applications
    mpv
    spotify
    imv
    zathura
    pinta
    # File managers
    kdePackages.dolphin
    xfce.thunar
    nemo
  ];

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
    };
    initExtra = ''
      # Enable menu-complete for cycling through completions
      bind '"\t":menu-complete'
      bind '"\e[Z":menu-complete-backward'  # Shift-Tab to go backwards
      bind 'set show-all-if-ambiguous on'
      bind 'set menu-complete-display-prefix on'

      # Query Ollama with ?
      function ? {
        ollama run qwen3:8b --think=false "$*"
      }

      # Query Claude with ?? (persistent session per shell)
      function ?? {
        if [ -z "$CLAUDE_SHELL_SESSION" ]; then
          export CLAUDE_SHELL_SESSION=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
          claude --print --verbose --output-format stream-json --include-partial-messages --session-id "$CLAUDE_SHELL_SESSION" "$@" | jq --unbuffered -j 'select(.event.type == "content_block_delta") | if .event.delta.type == "text_delta" then .event.delta.text elif .event.delta.type == "input_json_delta" and .event.delta.partial_json == "" then "\n🔧 " elif .event.delta.type == "input_json_delta" then .event.delta.partial_json + if (.event.delta.partial_json | endswith("}")) then "\n" else "" end else "" end'
          echo
        else
          claude --print --verbose --output-format stream-json --include-partial-messages --resume "$CLAUDE_SHELL_SESSION" "$@" | jq --unbuffered -j 'select(.event.type == "content_block_delta") | if .event.delta.type == "text_delta" then .event.delta.text elif .event.delta.type == "input_json_delta" and .event.delta.partial_json == "" then "\n🔧 " elif .event.delta.type == "input_json_delta" then .event.delta.partial_json + if (.event.delta.partial_json | endswith("}")) then "\n" else "" end else "" end'
          echo
        fi
      }
    '';
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    initContent = ''
      # Query Ollama with q
      function q {
        ollama run qwen3:8b --think=false "$*"
      }

      # Query Claude with qq (persistent session per shell)
      function qq {
        if [ -z "$CLAUDE_SHELL_SESSION" ]; then
          export CLAUDE_SHELL_SESSION=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
          claude --print --verbose --output-format stream-json --include-partial-messages --session-id "$CLAUDE_SHELL_SESSION" "$@" | jq --unbuffered -j 'select(.event.type == "content_block_delta") | if .event.delta.type == "text_delta" then .event.delta.text elif .event.delta.type == "input_json_delta" and .event.delta.partial_json == "" then "\n🔧 " elif .event.delta.type == "input_json_delta" then .event.delta.partial_json + if (.event.delta.partial_json | endswith("}")) then "\n" else "" end else "" end'
          echo
        else
          claude --print --verbose --output-format stream-json --include-partial-messages --resume "$CLAUDE_SHELL_SESSION" "$@" | jq --unbuffered -j 'select(.event.type == "content_block_delta") | if .event.delta.type == "text_delta" then .event.delta.text elif .event.delta.type == "input_json_delta" and .event.delta.partial_json == "" then "\n🔧 " elif .event.delta.type == "input_json_delta" then .event.delta.partial_json + if (.event.delta.partial_json | endswith("}")) then "\n" else "" end else "" end'
          echo
        fi
      }
    '';
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.bat = {
    enable = true;
  };

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.lazygit = {
    enable = true;
  };

  programs.btop = {
    enable = true;
  };

  # programs.delta = {
  #   enable = true;
  #   enableGitIntegration = true;
  # };

  programs.tmux = {
    enable = true;
  };

  programs.ripgrep = {
    enable = true;
  };

  programs.fd = {
    enable = true;
  };

  programs.gh = {
    enable = true;
  };

  programs.jq = {
    enable = true;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.helix = {
    enable = true;
    extraPackages = with pkgs; [
      # Language servers
      typescript-language-server
      rust-analyzer
      vscode-langservers-extracted  # json, html, css
      nil
      nixd
      # Python
      python312Packages.python-lsp-server
      ruff
      ty
    ];
  };

  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "fifc";
        src = pkgs.fishPlugins.fifc.src;
      }
    ];
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
    };
    shellInit = ''
      # fifc configuration
      set -U fifc_editor hx

      # Query Ollama with ?
      function ?
        ollama run qwen3:8b --think=false $argv
      end

      # Query Claude with ?? (persistent session per shell)
      function ??
        if test -z "$CLAUDE_SHELL_SESSION"
          set -gx CLAUDE_SHELL_SESSION (uuidgen 2>/dev/null; or cat /proc/sys/kernel/random/uuid)
          claude --print --verbose --output-format stream-json --include-partial-messages --session-id "$CLAUDE_SHELL_SESSION" "$argv" | jq --unbuffered -j 'select(.event.type == "content_block_delta") | if .event.delta.type == "text_delta" then .event.delta.text elif .event.delta.type == "input_json_delta" and .event.delta.partial_json == "" then "\n🔧 " elif .event.delta.type == "input_json_delta" then .event.delta.partial_json + if (.event.delta.partial_json | endswith("}")) then "\n" else "" end else "" end'
          echo
        else
          claude --print --verbose --output-format stream-json --include-partial-messages --resume "$CLAUDE_SHELL_SESSION" "$argv" | jq --unbuffered -j 'select(.event.type == "content_block_delta") | if .event.delta.type == "text_delta" then .event.delta.text elif .event.delta.type == "input_json_delta" and .event.delta.partial_json == "" then "\n🔧 " elif .event.delta.type == "input_json_delta" then .event.delta.partial_json + if (.event.delta.partial_json | endswith("}")) then "\n" else "" end else "" end'
          echo
        end
      end
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Smarak Nayak";
      user.email = "miltu.s.nayak@gmail.com";
      init.defaultBranch = "main";
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "org.kde.dolphin.desktop";
    };
  };

  age.identityPaths = [ "${config.home.homeDirectory}/.config/age/master.key" ];
  age.secrets.ssh-key = {
    file = ./secrets/ssh-key.age;
    path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    mode = "600";
  };
  xdg.configFile."waybar/config.jsonc".source = ./dotfiles/waybar/config.jsonc;
  xdg.configFile."waybar/config-niri.jsonc".source = ./dotfiles/waybar/config-niri.jsonc;
  xdg.configFile."waybar/style.css".source = ./dotfiles/waybar/style.css;
  xdg.configFile."waybar/scripts" = {
    source = ./dotfiles/waybar/scripts;
    recursive = true;
  };
  xdg.configFile."ghostty/config".source = ./dotfiles/ghostty/config;
  xdg.configFile."mako/config".source = ./dotfiles/mako/config;
  home.file.".claude/settings.json".source = ./dotfiles/claude/settings.json;

  xdg.desktopEntries.google-chrome = {
    name = "Google Chrome";
    exec = "google-chrome-stable --disable-features=WaylandWpColorManagerV1 %U";
    icon = "google-chrome";
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "text/xml" ];
    actions = {};
  };
  home.activation.clearWofiCache = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run rm -f $HOME/.cache/wofi-drun
  '';
  # Use home.activation instead of home.file for Variety script because:
  # - home.file creates read-only symlinks to Nix store
  # - Variety expects to manage its own ~/.config/variety/ directory
  # - Copying the script allows Variety to modify configs without breaking
  home.activation.installVarietyScript = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run mkdir -p $HOME/.config/variety/scripts
    run cp -f ${./dotfiles/variety/scripts/set_wallpaper} $HOME/.config/variety/scripts/set_wallpaper
    run chmod +x $HOME/.config/variety/scripts/set_wallpaper
  '';
}
