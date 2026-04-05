{ stdenv, fetchurl, libseccomp, glibc }:

let
  version = "0.0.49";
  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/sandbox-runtime/-/sandbox-runtime-${version}.tgz";
    hash = "sha256-FbCDtQ+Ce3suSLVP7nHeZ7aJVDlA/vDISEP6EqGfTSo=";
  };
in
stdenv.mkDerivation {
  pname = "claude-code-seccomp";
  inherit version src;

  sourceRoot = "package/vendor";

  nativeBuildInputs = [ libseccomp.dev ];
  buildInputs = [ libseccomp ];

  buildPhase = ''
    # BPFフィルタ生成ツール（動的リンク、ビルド時のみ）
    gcc -O2 -o seccomp-unix-block seccomp-src/seccomp-unix-block.c \
      -I${libseccomp.dev}/include -L${libseccomp}/lib -lseccomp -Wl,-rpath,${libseccomp}/lib

    # x86_64用BPFフィルタを生成
    ./seccomp-unix-block x86_64.bpf x86_64

    # BPFフィルタをCヘッダに変換
    {
      echo '#if defined(__x86_64__)'
      echo 'static const unsigned char unix_block_bpf[] = {'
      od -An -tx1 -v x86_64.bpf | sed 's/^ //;s/ /, 0x/g;s/^/    0x/;s/$/,/'
      echo '};'
      echo '#else'
      echo '#error "unsupported architecture"'
      echo '#endif'
    } > unix-block-bpf.h

    # apply-seccomp を静的リンクでビルド
    gcc -static -O2 -I. -o apply-seccomp seccomp-src/apply-seccomp.c \
      -L${glibc.static}/lib
    strip apply-seccomp
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/claude-code-seccomp
    cp apply-seccomp $out/bin/
    cp x86_64.bpf $out/share/claude-code-seccomp/unix-block.bpf
  '';

  meta = {
    description = "Seccomp filter for Claude Code sandbox (blocks Unix domain sockets)";
    platforms = [ "x86_64-linux" ];
  };
}
