{ buildFHSEnv, writeShellScript }:

# @opengsd/gsd-pi (GSD Pi コーディングエージェント CLI)
# prebuilt native (engine/koffi/sharp/node-pty/playwright) を install 時に取得するため
# 純 store 化は不可。FHS 環境の中で XDG data 配下へ npm install して実行する。
let
  version = "1.20.1";
  allowScripts = "@opengsd/gsd-pi @opengsd/gsd-browser koffi node-pty protobufjs";

  run = writeShellScript "gsd-run" ''
    set -euo pipefail
    prefix="''${XDG_DATA_HOME:-$HOME/.local/share}/gsd-pi/${version}"
    bin="$prefix/node_modules/.bin/gsd"
    if [ ! -e "$prefix/.installed" ]; then
      echo "gsd-pi ${version} を $prefix にインストールします..." >&2
      mkdir -p "$prefix"
      npm install --prefix "$prefix" --no-fund --no-audit "@opengsd/gsd-pi@${version}" >&2
      # npm 11 は依存の install script を既定でブロックする (--allow-scripts も project では不可)。
      # package.json の allowScripts に承認を書いてから rebuild で実行させる。
      # (native prebuild 取得・chromium/rtk のダウンロードはここで行われる)
      npm install-scripts approve --prefix "$prefix" ${allowScripts} >&2
      npm rebuild --prefix "$prefix" >&2
      touch "$prefix/.installed"
    fi
    exec "$bin" "$@"
  '';
in
buildFHSEnv {
  name = "gsd";
  inherit version;

  targetPkgs =
    p: with p; [
      nodejs_24
      git
      python3
      gcc
      gnumake
      pkg-config
      openssl
      zlib
      stdenv.cc.cc.lib

      # playwright (chromium) の実行時依存
      glib
      nss
      nspr
      atk
      at-spi2-atk
      at-spi2-core
      cups
      dbus
      expat
      libdrm
      libgbm
      mesa
      gtk3
      pango
      cairo
      alsa-lib
      libxkbcommon
      systemd # libudev
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
      libxshmfence
    ];

  runScript = run;

  meta.mainProgram = "gsd";
}
