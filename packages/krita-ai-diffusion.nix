{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "krita-ai-diffusion";

  src = pkgs.fetchFromGitHub {
    owner = "Acly";
    repo = "krita-ai-diffusion";
    fetchSubmodules = true;
    # Qt6/Krita 6 support, pending upstream merge:
    # https://github.com/Acly/krita-ai-diffusion/pull/2491
    rev = "bb8ffa235be41edeee5057aca013445d4872dadf";
    hash = "sha256-dFYtuBDL60pu7r6kujYTfQZxyGEyNwvZH88RG+lNChc=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/krita/pykrita
    cp -r ai_diffusion ai_diffusion.desktop scripts $out/share/krita/pykrita
    runHook postInstall
  '';
}
