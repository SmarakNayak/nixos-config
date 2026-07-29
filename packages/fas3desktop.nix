{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, alsa-lib
, atk
, cairo
, fontconfig
, freetype
, gdk-pixbuf
, glib
, gtk3
, libGL
, libxkbcommon
, pango
, wayland
, libx11
, libxcomposite
, libxcursor
, libxdamage
, libxext
, libxfixes
, libxi
, libxinerama
, libxrandr
, libxrender
, libxtst
, libxxf86vm
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fas3desktop";
  version = "3.0.73";

  src = fetchurl {
    url = "https://www.freeaccountingsoftware.com.au/FAS_3_Desktop_73.deb";
    hash = "sha256-PQBbw8ImST8d+w5+Ai2VlXNeDDjWWC1m1rPVgUQ+4Is=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    atk
    cairo
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libGL
    libxkbcommon
    pango
    wayland
    libx11
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxinerama
    libxrandr
    libxrender
    libxtst
    libxxf86vm
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt" "$out/bin" "$out/share/applications" "$out/share/pixmaps"
    cp -r opt/fas3desktop "$out/opt/"

    makeWrapper "$out/opt/fas3desktop/bin/FAS 3 Desktop 2027" "$out/bin/fas3desktop" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.buildInputs}
    ln -s "$out/opt/fas3desktop/lib/FAS_3_Desktop_2027.png" \
      "$out/share/pixmaps/fas3desktop.png"

    substitute "$out/opt/fas3desktop/lib/fas3desktop-FAS_3_Desktop_2027.desktop" \
      "$out/share/applications/fas3desktop.desktop" \
      --replace-fail 'Exec="/opt/fas3desktop/bin/FAS 3 Desktop 2027"' 'Exec=fas3desktop' \
      --replace-fail 'Icon=/opt/fas3desktop/lib/FAS_3_Desktop_2027.png' 'Icon=fas3desktop'

    runHook postInstall
  '';

  meta = {
    description = "Free Accounting Software (FAS 3 Desktop 2027)";
    homepage = "https://www.freeaccountingsoftware.com.au/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "fas3desktop";
  };
})
