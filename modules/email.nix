{ config, pkgs, lib, ... }:

let
  emails = import ../secrets/email.nix;
in
{
  home.packages = [ pkgs.thunderbird ];

  accounts.email.accounts = {
    gmail1 = {
      primary = true;
      address = emails.gmail1;
      realName = "Smarak Nayak";
      flavor = "gmail.com";
      imap = { host = "imap.gmail.com"; port = 993; tls.enable = true; };
      smtp = { host = "smtp.gmail.com"; port = 587; tls.enable = true; tls.useStartTls = true; };
      thunderbird.enable = true;
    };

    gmail2 = {
      address = emails.gmail2;
      realName = "Smarak Nayak";
      flavor = "gmail.com";
      imap = { host = "imap.gmail.com"; port = 993; tls.enable = true; };
      smtp = { host = "smtp.gmail.com"; port = 587; tls.enable = true; tls.useStartTls = true; };
      thunderbird.enable = true;
    };

    gmail3 = {
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
      smtp = { host = "smtp-mail.outlook.com"; port = 587; tls.enable = true; tls.useStartTls = true; };
      thunderbird.enable = true;
    };
  };

  programs.thunderbird = {
    enable = true;
    profiles.default.isDefault = true;
  };
}
