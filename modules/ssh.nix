{ pkgs, ... }:

{
  # OpenSSH starts with no identities; the user service below explicitly loads
  # only the Git forge keys.
  programs.ssh.startAgent = true;

  home-manager.users.miltu = { config, ... }: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = {
          Hostname = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/id_github";
          IdentitiesOnly = "yes";
        };
        "gitlab.com" = {
          Hostname = "gitlab.com";
          User = "git";
          IdentityFile = "~/.ssh/id_gitlab";
          IdentitiesOnly = "yes";
        };
        "antec-pc" = {
          Hostname = "antec-pc";
          User = "miltu";
          IdentityFile = "~/.ssh/antec-admin";
          IdentityAgent = "none";
          IdentitiesOnly = "yes";
        };
        "antec-pc-local" = {
          Hostname = "antec-pc.local";
          User = "miltu";
          IdentityFile = "~/.ssh/antec-admin";
          IdentityAgent = "none";
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

    age.secrets.ssh-key-github = {
      file = ../secrets/ssh-key-github.age;
      path = "${config.home.homeDirectory}/.ssh/id_github";
      mode = "600";
    };
    age.secrets.ssh-key-gitlab = {
      file = ../secrets/ssh-key-gitlab.age;
      path = "${config.home.homeDirectory}/.ssh/id_gitlab";
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

    # Load only the Git forge identities after the agent and Agenix secrets are
    # ready. The Antec key is never exposed through the forwarded agent socket.
    systemd.user.services.ssh-agent-keys = {
      Unit = {
        Description = "Load Git forge keys into the SSH agent";
        Requires = [ "agenix.service" "ssh-agent.service" ];
        After = [ "agenix.service" "ssh-agent.service" ];
        PartOf = [ "agenix.service" "ssh-agent.service" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
        ExecStart = "${pkgs.openssh}/bin/ssh-add %h/.ssh/id_github %h/.ssh/id_gitlab";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
