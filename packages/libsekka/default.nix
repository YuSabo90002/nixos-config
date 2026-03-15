{ lib
, rustPlatform
, cargo-c
, pkg-config
, skkDictionaries
, nkf
}:

let
  src = builtins.fetchGit {
    url = "/home/yuta/Documents/sekka-fcitx5";
    ref = "HEAD";
  };

  # SKK-JISYO.LをUTF-8に変換したもの
  skk-jisyo-utf8 = builtins.derivation {
    name = "skk-jisyo-utf8";
    system = "x86_64-linux";
    builder = "/bin/sh";
    args = [
      "-c"
      "${nkf}/bin/nkf -w ${skkDictionaries.l}/share/skk/SKK-JISYO.L > $out"
    ];
  };
in
rustPlatform.buildRustPackage {
  pname = "libsekka";
  version = "0.1.0";

  src = "${src}/libsekka";

  cargoHash = lib.fakeHash;

  nativeBuildInputs = [
    cargo-c
    pkg-config
  ];

  # cargo-cでCライブラリとしてビルド・インストール
  buildPhase = ''
    cargo cbuild --release --frozen
  '';

  installPhase = ''
    cargo cinstall --release --frozen --prefix=$out
  '';

  # 辞書生成も行う
  postInstall = ''
    mkdir -p $out/share/fcitx5/sekka
    cargo run --release --frozen --bin sekka-dict-tool -- \
      convert ${skk-jisyo-utf8} --output $out/share/fcitx5/sekka/master-dict.db
  '';

  meta = with lib; {
    description = "日本語入力変換ライブラリ Sekka（石火）";
    license = with licenses; [ mit asl20 ];
  };
}
