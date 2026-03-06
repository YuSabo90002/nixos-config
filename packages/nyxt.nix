{ stdenv, lib, fetchurl, buildFHSEnv, squashfsTools, glib, nss, xorg, mesa,
  alsa-lib, cups, at-spi2-atk, libdrm, gtk3, pango, cairo, libxkbcommon,
  dbus, expat, nspr, atk, gdk-pixbuf, zlib }:

# nixpkgs PR #491363 がマージされるまでの暫定パッケージ
# リリース済みのAppImageを展開してFHS環境で実行
# nyxt AppImage内にcl-electron-server AppImageが入れ子になっているため、両方展開する
let
  nyxt-extracted = stdenv.mkDerivation {
    pname = "nyxt-extracted";
    version = "4.0.0";

    src = fetchurl {
      url = "https://github.com/atlas-engineer/nyxt/releases/download/4.0.0/Linux-Nyxt-x86_64.tar.gz";
      hash = "sha256-v+x6K5svLA3L+IjEdTjmJEf3hvgwhwrvqAcelpY1ScQ=";
    };

    dontUnpack = true;
    dontStrip = true;
    dontPatchELF = true;

    nativeBuildInputs = [ squashfsTools ];

    installPhase = ''
      # nyxt AppImage を展開
      tar xzf $src
      chmod +x Nyxt-x86_64.AppImage
      ./Nyxt-x86_64.AppImage --appimage-extract

      mkdir -p $out/nyxt
      cp -r squashfs-root/* $out/nyxt/

      # cl-electron-server AppImage を展開
      unsquashfs -o 188392 -d $out/cl-electron-server $out/nyxt/usr/bin/cl-electron-server

      # cl-electron-server AppImageを展開済みバイナリで置き換え
      rm $out/nyxt/usr/bin/cl-electron-server
      cat > $out/nyxt/usr/bin/cl-electron-server <<'WRAPPER'
      #!/bin/bash
      SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
      CL_ELECTRON_DIR="PLACEHOLDER"
      exec "$CL_ELECTRON_DIR/cl-electron-server" "$@"
      WRAPPER
      chmod +x $out/nyxt/usr/bin/cl-electron-server
      substituteInPlace $out/nyxt/usr/bin/cl-electron-server \
        --replace-quiet "PLACEHOLDER" "$out/cl-electron-server"
    '';
  };
in
buildFHSEnv {
  name = "nyxt";
  version = "4.0.0";

  targetPkgs = pkgs: [
    pkgs.glib
    pkgs.zlib
    pkgs.nss
    pkgs.nspr
    pkgs.mesa
    pkgs.alsa-lib
    pkgs.cups
    pkgs.at-spi2-atk
    pkgs.atk
    pkgs.libdrm
    pkgs.gtk3
    pkgs.pango
    pkgs.cairo
    pkgs.gdk-pixbuf
    pkgs.libxkbcommon
    pkgs.dbus
    pkgs.expat
    pkgs.xorg.libX11
    pkgs.xorg.libXcomposite
    pkgs.xorg.libXdamage
    pkgs.xorg.libXext
    pkgs.xorg.libXfixes
    pkgs.xorg.libXrandr
    pkgs.xorg.libxcb
    pkgs.libgbm
    pkgs.libnotify
    pkgs.systemd
  ];

  runScript = "${nyxt-extracted}/nyxt/AppRun";

  extraBwrapArgs = [
    "--setenv" "APPDIR" "${nyxt-extracted}/nyxt"
  ];

  meta = {
    description = "Infinitely extensible web-browser";
    mainProgram = "nyxt";
    homepage = "https://nyxt.atlas.engineer";
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
  };
}
