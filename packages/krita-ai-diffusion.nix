{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "krita-ai-diffusion";

  src = pkgs.fetchFromGitHub {
    owner = "Acly";
    repo = "krita-ai-diffusion";
    fetchSubmodules = true;
    rev = "v1.49.0";
    hash = "sha256-RXMF2Pc8hTDugxXYCbfeSH3DWLxMUeE5Ox4b5iE7QqE=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/krita/pykrita
    cp -r ai_diffusion ai_diffusion.desktop scripts $out/share/krita/pykrita
    runHook postInstall
  '';
}
