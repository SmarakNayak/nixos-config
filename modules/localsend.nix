{ lib, pkgs, ... }:

{
  programs.localsend = {
    enable = true;
    openFirewall = true;
    # LocalSend 1.18.0 needs libz.so.1 but omits zlib from its runtime search path.
    # Wrap the cached package to avoid rebuilding the Flutter application.
    # Remove this workaround once our nixpkgs pin includes the upstream fix:
    # https://github.com/NixOS/nixpkgs/pull/585411
    package = pkgs.symlinkJoin {
      name = "localsend-${pkgs.localsend.version}-with-zlib";
      paths = [ pkgs.localsend ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram "$out/bin/localsend_app" \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.zlib ]}
      '';
      inherit (pkgs.localsend) meta;
    };
  };
}
