{ config, pkgs, lib, ... }:

let
  claude-distro = import ./distrobox-packages/claude-code.nix { inherit pkgs; };
in
{
  home.username = "miltu";
  home.homeDirectory = "/home/miltu";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    curl
    distrobox
    claude-distro
    claude-code
    speedtest-go
    networkmanagerapplet
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    # CLI tools without home-manager modules
    procs
    sd
  ];
  
  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
    };
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.bat = {
    enable = true;
  };

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.lazygit = {
    enable = true;
  };

  programs.btop = {
    enable = true;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

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

  # Example: Configure git (you can remove this from configuration.nix if you move it here)
  # programs.git = {
  #   enable = true;
  #   userName = "Smarak Nayak";
  #   userEmail = "miltu.s.nayak@gmail.com";
  #   extraConfig = {
  #     init.defaultBranch = "main";
  #   };
  # };
  xdg.configFile."waybar/config.jsonc".source = ./dotfiles/waybar/config.jsonc;
  xdg.configFile."waybar/config-niri.jsonc".source = ./dotfiles/waybar/config-niri.jsonc;
  xdg.configFile."waybar/style.css".source = ./dotfiles/waybar/style.css;
  xdg.configFile."waybar/scripts" = {
    source = ./dotfiles/waybar/scripts;
    recursive = true;
  };
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
}
