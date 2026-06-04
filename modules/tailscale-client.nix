{ config, ... }:

let
  tailscaleInterface = config.services.tailscale.interfaceName;
in
{
  services.tailscale.enable = true;

  # Clients may initiate Tailscale connections, but tailnet peers should not
  # initiate new connections back into these machines.
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw -i ${tailscaleInterface} -m conntrack --ctstate NEW -j DROP
    ip6tables -I nixos-fw -i ${tailscaleInterface} -m conntrack --ctstate NEW -j DROP
  '';
  # Remove the inserted rules when the NixOS firewall is stopped or reloaded
  # (rules are reloaded on restart).
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -i ${tailscaleInterface} -m conntrack --ctstate NEW -j DROP || true
    ip6tables -D nixos-fw -i ${tailscaleInterface} -m conntrack --ctstate NEW -j DROP || true
  '';
}
