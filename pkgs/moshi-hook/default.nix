{
  lib,
  stdenvNoCC,
  fetchurl,
}:

# Moshi (iOS の SSH/mosh ターミナル) のホスト側ヘルパー。
# クライアントは SSH 越しに `command -v moshi-hook` を叩いて存在を確認し、
# cwd 一覧やセッション状態の取得に使う。
#
# 公開ソースリポジトリが無く、GoReleaser 製のビルド済みバイナリのみが CDN で
# 配布される。static link の Go バイナリなので autoPatchelfHook は不要。
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "moshi-hook";
  version = "0.2.69";

  src = fetchurl {
    url = "https://cdn.getmoshi.app/hook/v${finalAttrs.version}/moshi-hook_Linux_x86_64.tar.gz";
    # Homebrew tap (rjyo/homebrew-moshi) の Formula と同じ sha256
    hash = "sha256-OQPi5dHboC+eH1PfjOpuKzJg4VgUYbmgfKZfGIFLiwg=";
  };

  # tar のトップレベルにディレクトリが無く moshi-hook / README.md / docs が直接入っている
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 moshi-hook $out/bin/moshi-hook
    # 上流の Formula / install.sh は moshi を moshi-hook への symlink として置く
    ln -s moshi-hook $out/bin/moshi

    install -Dm644 README.md -t $out/share/doc/${finalAttrs.pname}
    install -Dm644 docs/*.md -t $out/share/doc/${finalAttrs.pname}/docs

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/moshi-hook --version | grep -F "${finalAttrs.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Daemon and CLI bridging AI coding agents to the Moshi mobile app";
    homepage = "https://getmoshi.app";
    downloadPage = "https://github.com/rjyo/homebrew-moshi";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    license = lib.licenses.unfree; # ソース非公開・ライセンス表記なし
    platforms = [ "x86_64-linux" ];
    mainProgram = "moshi-hook";
  };
})
