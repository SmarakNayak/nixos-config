{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "krita-vision-tools";

  src = pkgs.fetchurl {
    url = "https://github.com/Acly/krita-vision-tools/releases/download/v2.1.0/krita_vision_tools-linux-x64-2.1.1.zip";
    hash = "sha256-pSS929jHx6tRxzP7mzIEaPVNKb4T8/q/of+BB3IeYnU=";
  };

  nativeBuildInputs = [ pkgs.unzip pkgs.autoPatchelfHook ];
  buildInputs = [ pkgs.krita pkgs.stdenv.cc.cc.lib pkgs.vulkan-loader ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/krita/pykrita
    cp -r vision_tools vision_tools.desktop $out/share/krita/pykrita
    runHook postInstall
  '';
}
