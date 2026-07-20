{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "krita-vision-tools";

  src = pkgs.fetchurl {
    url = "https://github.com/Acly/krita-vision-tools/releases/download/v3.0.0-pre/krita_vision_tools-linux-x64-3.0.0.zip";
    hash = "sha256-sZTqjKpy+Yxb2pB+O7ITzfHTTFqd/ZmogYoFLAfnypI=";
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
