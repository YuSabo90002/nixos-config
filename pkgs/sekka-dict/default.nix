{ lib
, stdenv
, fetchurl
, libsekka
}:

# master 辞書 (SKK-JISYO.L から生成する 175,789 キーの不変辞書)。
#
# fcitx5-sekka 側の -DSEKKA_BUILD_DICT=ON は CMake の file(DOWNLOAD) で
# SKK-JISYO.L を取りに行くのでサンドボックスでは動かない。commit と SHA256 は
# 上流 fcitx5-sekka/cmake/FetchSkkJisyo.cmake が固定しているものと同じで、
# ここでは fetchurl に置き換えている。
#
# アドオン本体と派生を分けてあるので、.cpp を直すたびに数分かかる 62MB の
# 辞書生成が走らない。
let
  skkJisyo = fetchurl {
    url = "https://raw.githubusercontent.com/skk-dev/dict/14a1df7ec8f84410f5fb006978cf00878768150a/SKK-JISYO.L";
    sha256 = "c791f578d1b4040fce282db29bc22b2cc7ea46f83e269fab2e0fa779e2967e40";
  };
in
stdenv.mkDerivation {
  pname = "sekka-dict";
  inherit (libsekka) version;

  dontUnpack = true;

  nativeBuildInputs = [ libsekka ];

  # SKK-JISYO.L は EUC-JP なので --encoding は auto のまま (自動判別) に任せる。
  buildPhase = ''
    runHook preBuild
    sekka-dict-tool convert ${skkJisyo} --output master-dict.db
    runHook postBuild
  '';

  # mode 444 は必須。fcitx5-sekka は mmap した辞書を書き換えられると SIGBUS で
  # fcitx5 ごと落ちるため、access(W_OK) が通るパスの辞書を読み込まない。
  # store の中なので実際は読み取り専用だが、意図を明示しておく。
  installPhase = ''
    runHook preInstall
    install -Dm444 master-dict.db "$out/share/fcitx5/sekka/master-dict.db"
    runHook postInstall
  '';

  meta = {
    description = "Sekka の master 辞書 (SKK-JISYO.L から生成)";
    homepage = "https://github.com/YuSabo90002/libsekka";
    # 生成物は SKK-JISYO.L 由来なので辞書側のライセンスに従う
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
