{ lib
, stdenv
, cmake
, kdePackages
, pkg-config
, gettext
, gtest
, fcitx5
, libsekka
, src
, version
}:

# fcitx5 アドオン本体。
#
# 辞書パスは一切パッチしない。v0.2.0 の src/sekkadictpath.cpp は DictionaryPath が
# 空なら StandardPaths::locateAll(PkgData, "sekka/master-dict.db") で探索し、
# nixpkgs の fcitx5-with-addons ラッパーが symlinkJoin 自身の share を
# XDG_DATA_DIRS に足すので、i18n.inputMethod.fcitx5.addons に入れた sekka-dict の
# share/fcitx5/sekka/ がそのまま探索対象になる。
#
# -DSEKKA_BUILD_DICT は OFF のまま (既定値)。辞書は sekka-dict 派生が作る。
stdenv.mkDerivation {
  pname = "fcitx5-sekka";
  inherit src version;

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    pkg-config
    gettext # po/ の msgfmt と fcitx5_translate_desktop_file
  ];

  # gtest は ENABLE_TEST=ON の configure 時に find_package(GTest) が要るので
  # nativeCheckInputs ではなく buildInputs に置く。
  buildInputs = [
    fcitx5
    libsekka
    gtest
  ];

  cmakeFlags = [
    (lib.cmakeBool "ENABLE_TEST" true)
  ];

  doCheck = true;

  # StandardPaths のコンストラクタは HOME も XDG_DATA_HOME も無いと
  # std::runtime_error("Home is not set") を投げる。サンドボックスの
  # HOME=/homeless-shelter は存在しないので書ける場所を渡す。
  preCheck = ''
    export HOME="$TMPDIR"
  '';

  meta = {
    description = "Sekka 日本語入力メソッドの fcitx5 アドオン";
    homepage = "https://github.com/YuSabo90002/fcitx5-sekka";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
