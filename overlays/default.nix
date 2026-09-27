{ inputs }:
[
  (final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  })

  # 自作の日本語入力メソッド (sekka)。flake input を src に渡す必要があるので
  # packages/ の autoWire (pkgs.callPackage <dir> { }) には乗らない。
  # overlay にしておくと fcitx5-sekka -> libsekka -> sekka-dict の相互参照が
  # callPackage 任せで解決する。
  (final: _prev: {
    libsekka = final.callPackage ../pkgs/libsekka {
      src = inputs.libsekka;
      version = "0.3.0";
    };
    sekka-dict = final.callPackage ../pkgs/sekka-dict { };
    fcitx5-sekka = final.callPackage ../pkgs/fcitx5-sekka {
      src = inputs.fcitx5-sekka;
      version = "0.3.0";
    };
  })

  inputs.llm-agents.overlays.shared-nixpkgs
  inputs.nix-vscode-extensions.overlays.default
]
