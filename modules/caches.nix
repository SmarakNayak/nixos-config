{ ... }:
{
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://cache.numtide.com"
    "https://cache.nixos-cuda.org"
    "https://symbolics.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    "symbolics.cachix.org-1:Wdgpxequ4fzP4FAckIf4MqMG9OpNxWz6CttNwiGf4AI="
  ];
}
