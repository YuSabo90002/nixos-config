{ lib
, stdenv
, cmake
, extra-cmake-modules
, pkg-config
, fcitx5
, libsekka
}:

let
  src = builtins.fetchGit {
    url = "/home/yuta/Documents/sekka-fcitx5";
    ref = "HEAD";
  };
in
stdenv.mkDerivation {
  pname = "fcitx5-sekka";
  version = "0.1.0";

  src = "${src}/fcitx5-sekka";

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    pkg-config
  ];

  buildInputs = [
    fcitx5
    libsekka
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
  ];

  # libsekkaの辞書データもインストール先に含める
  postInstall = ''
    ln -s ${libsekka}/share/fcitx5/sekka $out/share/fcitx5/sekka
  '';

  meta = with lib; {
    description = "fcitx5用Sekka日本語入力モジュール";
    license = with licenses; [ mit asl20 ];
  };
}
