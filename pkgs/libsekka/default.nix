{ lib
, stdenv
, rustPlatform
, buildPackages
, cargo-c
, pkg-config
, src
, version
}:

# 日本語かな漢字変換ライブラリ本体。cargo-c で C ABI の共有ライブラリ・ヘッダ・
# pkg-config ファイルを出し、fcitx5-sekka はそれを pkg-config 経由で参照する。
#
# 通常の buildRustPackage の build/install で bin/sekka-dict-tool が出て、
# postBuild/postInstall の cbuild/cinstall で C API 側が出る。前例は nixpkgs の
# libimagequant / rav1e。
rustPlatform.buildRustPackage {
  pname = "libsekka";
  inherit src version;

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [ cargo-c pkg-config ];

  # cargo-c は Cargo.toml の [features] capi を自動で有効にする。
  # --libdir=lib は必須: 付けないと環境次第で lib64 に落ち、sekka.pc の libdir も
  # そちらを向くので pkg_check_modules が拾えなくなる。
  postBuild = ''
    ${buildPackages.rust.envVars.setEnv} cargo cbuild \
      --release --frozen \
      --prefix=${placeholder "out"} --libdir=lib \
      --target ${stdenv.hostPlatform.rust.rustcTarget}
  '';

  postInstall = ''
    ${buildPackages.rust.envVars.setEnv} cargo cinstall \
      --release --frozen \
      --prefix=${placeholder "out"} --libdir=lib \
      --target ${stdenv.hostPlatform.rust.rustcTarget}
  '';

  meta = {
    description = "Sekka 入力モデルの日本語かな漢字変換ライブラリ";
    homepage = "https://github.com/YuSabo90002/libsekka";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    pkgConfigModules = [ "sekka" ];
    mainProgram = "sekka-dict-tool";
  };
}
