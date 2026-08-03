# pkgs/

`packages/` に置いたディレクトリは nixos-unified の autoWire が
`pkgs.callPackage <dir> { }` で自動的にフレーク出力 (`.#<名前>`) にする。
この呼び出し方に乗らないパッケージをここに置く。オプトアウトの仕組みが
autowire 側に無いため、ディレクトリを分けるのが唯一の逃げ道になる。

`packages/` に置くと `nix flake check` と `nix flake show` が丸ごと落ちる例:

- `hori-truck-wheel` — 引数に `kernel` を取る。トップレベル `pkgs` には無く
  `linuxPackages` スコープにしかないので callPackage が埋められない。
  利用側は `config.boot.kernelPackages.callPackage` で呼ぶ。
- `moshi-hook` — `meta.license = unfree`。フレーク側の pkgs には allowUnfree が
  無いため弾かれる。利用側 (nixosConfigurations の pkgs) は allowUnfree = true。

ここのパッケージは利用箇所から `pkgs.callPackage ../../pkgs/<名前> { }` で直接呼ぶ。
