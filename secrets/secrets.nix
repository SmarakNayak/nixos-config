let
  # Your master key public part
  master = "age1amd42k828cgyv6kk8pltkknpxklyauz8pnzde73spp8l2w2n5qgsgdsjlu";
in {
  "ssh-key.age".publicKeys = [ master ];
  "ssh-key-hetzner.age".publicKeys = [ master ];
}
