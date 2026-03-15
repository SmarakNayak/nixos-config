{ config, pkgs, lib, ... }:

let
  secretsFile = ../secrets/email.nix;
  isDecrypted = builtins.substring 0 24 (builtins.readFile secretsFile) == "# THIS_FILE_IS_DECRYPTED";
  emails = if isDecrypted then import secretsFile else {
    gmail1        = "gmail1@example.com";
    gmail2        = "gmail2@example.com";
    gmail3        = "gmail3@example.com";
    hotmail       = "hotmail@example.com";
    hotmailAlias1 = "alias1@example.com";
    hotmailAlias2 = "alias2@example.com";
  };
in
{
  accounts.email.accounts = {
    gmail-casual = {
      primary = true;
      address = emails.gmail1;
      realName = "Smarak Nayak";
      flavor = "gmail.com";
      imap = { host = "imap.gmail.com"; port = 993; tls.enable = true; };
      smtp = { host = "smtp.gmail.com"; port = 587; tls.enable = true; tls.useStartTls = true; };
      thunderbird.enable = true;
    };

    gmail-proper = {
      address = emails.gmail2;
      realName = "Smarak Nayak";
      flavor = "gmail.com";
      imap = { host = "imap.gmail.com"; port = 993; tls.enable = true; };
      smtp = { host = "smtp.gmail.com"; port = 587; tls.enable = true; tls.useStartTls = true; };
      thunderbird.enable = true;
    };

    gmail-work = {
      address = emails.gmail3;
      realName = "Smarak Nayak";
      flavor = "gmail.com";
      imap = { host = "imap.gmail.com"; port = 993; tls.enable = true; };
      smtp = { host = "smtp.gmail.com"; port = 587; tls.enable = true; tls.useStartTls = true; };
      thunderbird.enable = true;
    };

    hotmail = {
      address = emails.hotmail;
      realName = "Smarak Nayak";
      userName = emails.hotmail;
      aliases = [ emails.hotmailAlias1 emails.hotmailAlias2 ];
      imap = { host = "outlook.office365.com"; port = 993; tls.enable = true; };
      smtp = { host = "smtp.office365.com"; port = 587; tls.enable = true; tls.useStartTls = true; };
      thunderbird = {
        enable = true;
        settings = id: {
          "mail.server.server_${id}.authMethod" = 10;
          "mail.smtpserver.smtp_${id}.authMethod" = 10;
        };
      };
    };
  };

  programs.thunderbird = {
    enable = true;
    profiles.default.isDefault = true;
    package = pkgs.thunderbird.override {
      extraPolicies.ExtensionSettings = {
        "{4753278b-acea-4b2b-a111-1fc9450d239d}" = {
          installation_mode = "normal_installed";
          install_url = "https://addons.thunderbird.net/thunderbird/downloads/file/1044595/betterunsubscribe-2.8.0-tb.xpi";
        };
      };
    };
  };
}
