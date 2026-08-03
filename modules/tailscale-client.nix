{ config, ... }:

let
  tailscaleInterface = config.services.tailscale.interfaceName;
in
{
  services.tailscale.enable = true;

  # Deny new inbound tailnet connections by default, while allowing Syncthing's
  # direct TCP and QUIC transports. The ACCEPT rules are inserted after the DROP
  # rules so that `iptables -I` places them first in the chain.
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw -i ${tailscaleInterface} -m conntrack --ctstate NEW -j DROP
    ip6tables -I nixos-fw -i ${tailscaleInterface} -m conntrack --ctstate NEW -j DROP

    iptables -I nixos-fw -i ${tailscaleInterface} -p tcp --dport 22000 -j ACCEPT
    iptables -I nixos-fw -i ${tailscaleInterface} -p udp --dport 22000 -j ACCEPT
    ip6tables -I nixos-fw -i ${tailscaleInterface} -p tcp --dport 22000 -j ACCEPT
    ip6tables -I nixos-fw -i ${tailscaleInterface} -p udp --dport 22000 -j ACCEPT
  '';

  # Remove the inserted rules when the NixOS firewall is stopped or reloaded
  # (rules are reloaded on restart).
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -i ${tailscaleInterface} -p tcp --dport 22000 -j ACCEPT || true
    iptables -D nixos-fw -i ${tailscaleInterface} -p udp --dport 22000 -j ACCEPT || true
    ip6tables -D nixos-fw -i ${tailscaleInterface} -p tcp --dport 22000 -j ACCEPT || true
    ip6tables -D nixos-fw -i ${tailscaleInterface} -p udp --dport 22000 -j ACCEPT || true

    iptables -D nixos-fw -i ${tailscaleInterface} -m conntrack --ctstate NEW -j DROP || true
    ip6tables -D nixos-fw -i ${tailscaleInterface} -m conntrack --ctstate NEW -j DROP || true
  '';
}
