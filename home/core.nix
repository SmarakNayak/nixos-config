{ config, pkgs, ... }:

let
  claude-sandbox = import ../packages/claude-sandbox.nix { inherit pkgs; };
  opencode-sandbox = import ../packages/opencode-sandbox.nix { inherit pkgs; };
  codex-sandbox = import ../packages/codex-sandbox.nix { inherit pkgs; };
  pi-sandbox = import ../packages/pi-sandbox.nix { inherit pkgs; };
in
{
  imports = [
    ../scripts.nix
  ];

  home.username = "miltu";
  home.homeDirectory = "/home/miltu";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    curl
    git-agecrypt
    claude-sandbox
    claude-code
    opencode-sandbox
    llm-agents.opencode
    codex-sandbox
    llm-agents.codex
    pi-sandbox
    llm-agents.pi
    llm-agents.gemini-cli
    speedtest-go
    procs
    sd
    fastfetch
    unzip
    file
    tree
  ];

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
      rebuild-antec = "nixos-rebuild switch --flake ~/nixos-config#antec-pc --target-host antec-pc --sudo --ask-sudo-password";
      rebuild-antec-ts = "nixos-rebuild switch --flake ~/nixos-config#antec-pc --target-host antec-pc-ts --sudo --ask-sudo-password";
      ssh-antec = "ssh -t antec-pc fish -l";
      ssh-antec-ts = "ssh -t antec-pc-ts fish -l";
      vm-run = "nix run ~/nixos-config#test-vm";
    };
    initExtra = ''
      export SHELL=${pkgs.bash}/bin/bash

      bind '"\t":menu-complete'
      bind '"\e[Z":menu-complete-backward'
      bind 'set show-all-if-ambiguous on'
      bind 'set menu-complete-display-prefix on'

      function ? {
        if command -v ollama >/dev/null 2>&1; then
          ollama run qwen3:8b --think=false "$*"
        else
          echo "ollama is not installed in this profile" >&2
          return 127
        fi
      }

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
      rebuild-antec = "nixos-rebuild switch --flake ~/nixos-config#antec-pc --target-host antec-pc --sudo --ask-sudo-password";
      rebuild-antec-ts = "nixos-rebuild switch --flake ~/nixos-config#antec-pc --target-host antec-pc-ts --sudo --ask-sudo-password";
      ssh-antec = "ssh -t antec-pc fish -l";
      ssh-antec-ts = "ssh -t antec-pc-ts fish -l";
      vm-run = "nix run ~/nixos-config#test-vm";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    initContent = ''
      export SHELL=${pkgs.zsh}/bin/zsh

      function q {
        if command -v ollama >/dev/null 2>&1; then
          ollama run qwen3:8b --think=false "$*"
        else
          echo "ollama is not installed in this profile" >&2
          return 127
        fi
      }

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
    flags = [ "--disable-up-arrow" "--disable-ai" ];
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

  programs.bat.enable = true;

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.lazygit.enable = true;
  programs.btop.enable = true;
  programs.tmux.enable = true;
  programs.ripgrep.enable = true;
  programs.fd.enable = true;
  programs.gh.enable = true;
  programs.jq.enable = true;

  programs.starship = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.helix = {
    enable = true;
    extraPackages = with pkgs; [
      typescript-language-server
      rust-analyzer
      vscode-langservers-extracted
      nil
      nixd
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
      rebuild-antec = "nixos-rebuild switch --flake ~/nixos-config#antec-pc --target-host antec-pc --sudo --ask-sudo-password";
      rebuild-antec-ts = "nixos-rebuild switch --flake ~/nixos-config#antec-pc --target-host antec-pc-ts --sudo --ask-sudo-password";
      ssh-antec = "ssh -t antec-pc fish -l";
      ssh-antec-ts = "ssh -t antec-pc-ts fish -l";
      vm-run = "nix run ~/nixos-config#test-vm";
    };
    shellInit = ''
      set -g SHELL ${pkgs.fish}/bin/fish
      set -U fifc_editor hx

      function ?
        if command -q ollama
          ollama run qwen3:8b --think=false $argv
        else
          echo "ollama is not installed in this profile" >&2
          return 127
        end
      end

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
    lfs.enable = true;
    settings = {
      user.name = "Smarak Nayak";
      user.email = "miltu.s.nayak@gmail.com";
      init.defaultBranch = "main";
      "git-agecrypt \"config\"" = {
        identity = "${config.home.homeDirectory}/.config/age/master.key";
      };
    };
    includes = [{
      condition = "hasconfig:remote.*.url:*github.com*SmarakNayak/nixos-config.git";
      contents = {
        "filter \"git-agecrypt\"" = {
          required = true;
          smudge = "${pkgs.git-agecrypt}/bin/git-agecrypt smudge -f %f";
          clean = "${pkgs.git-agecrypt}/bin/git-agecrypt clean -f %f";
        };
        "diff \"git-agecrypt\"" = {
          textconv = "${pkgs.git-agecrypt}/bin/git-agecrypt textconv";
        };
      };
    }];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "antec-pc" = {
        Hostname = "antec-pc.local";
        User = "miltu";
        IdentityFile = "~/.ssh/antec-admin";
        IdentitiesOnly = "yes";
      };
      "antec-pc-ts" = {
        Hostname = "antec-pc";
        User = "miltu";
        IdentityFile = "~/.ssh/antec-admin";
        IdentitiesOnly = "yes";
      };
      "hetzner-green" = {
        Hostname = "65.21.25.120";
        User = "ubuntu";
        IdentityFile = "~/.ssh/id_hetzner";
        Compression = "yes";
        SetEnv = { TERM = "xterm-256color"; };
      };
      "hetzner-blue" = {
        Hostname = "37.27.139.85";
        User = "ubuntu";
        IdentityFile = "~/.ssh/id_hetzner";
        Compression = "yes";
        SetEnv = { TERM = "xterm-256color"; };
      };
    };
  };

  age.identityPaths = [ "${config.home.homeDirectory}/.config/age/master.key" ];
  age.secrets.ssh-key = {
    file = ../secrets/ssh-key.age;
    path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    mode = "600";
  };
  age.secrets.ssh-key-hetzner = {
    file = ../secrets/ssh-key-hetzner.age;
    path = "${config.home.homeDirectory}/.ssh/id_hetzner";
    mode = "600";
  };
  age.secrets.antec-admin-ssh-key = {
    file = ../secrets/antec-admin-ssh-key.age;
    path = "${config.home.homeDirectory}/.ssh/antec-admin";
    mode = "600";
  };
  age.secrets.smarak-agent-github-app = {
    file = ../secrets/smarak-agent-github-app.age;
    path = "${config.home.homeDirectory}/.config/smarak-agent/smarak-agent-github-app.pem";
    mode = "600";
  };
  age.secrets.deepseek-api-key = {
    file = ../secrets/deepseek-api-key.age;
    path = "${config.home.homeDirectory}/.config/opencode/deepseek-api-key";
  };
  age.secrets.zai-api-key = {
    file = ../secrets/zai-api-key.age;
    path = "${config.home.homeDirectory}/.config/opencode/zai-api-key";
    mode = "600";
  };
  age.secrets.pi-deepseek-api-key = {
    file = ../secrets/deepseek-api-key.age;
    path = "${config.home.homeDirectory}/.pi/agent/deepseek-api-key";
    mode = "600";
  };
  age.secrets.pi-zai-api-key = {
    file = ../secrets/zai-api-key.age;
    path = "${config.home.homeDirectory}/.pi/agent/zai-api-key";
    mode = "600";
  };

  home.file.".claude/settings.json".source = ../dotfiles/claude/settings.json;
  home.file.".pi/agent/auth.json".text = builtins.toJSON {
    deepseek = {
      type = "api_key";
      key = "!cat ${config.age.secrets.pi-deepseek-api-key.path}";
    };
    zai = {
      type = "api_key";
      key = "!cat ${config.age.secrets.pi-zai-api-key.path}";
    };
  };
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    provider.deepseek.options.apiKey = "{file:${config.age.secrets.deepseek-api-key.path}}";
    provider.zai.options.apiKey = "{file:${config.age.secrets.zai-api-key.path}}";
    provider.zai.models."glm-5.2" = {
      name = "GLM-5.2";
      family = "glm";
      attachment = false;
      reasoning = true;
      tool_call = true;
      interleaved.field = "reasoning_content";
      temperature = true;
      release_date = "2026-06-13";
      modalities = {
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        context = 1000000;
        output = 131072;
      };
      cost = {
        input = 1.4;
        output = 4.4;
        cache_read = 0.26;
        cache_write = 0;
      };
    };
  };
}
