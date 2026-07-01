{ inputs }:
let
  # nixpkgs 26.05 の gnupg 2.4.9 で quick-key-manipulation.scm が失敗するため
  # テストを無効化してビルドを通す (gcr/gnome-keyring/gvfs/flatpak/podman 等の依存元)
  gnupgNoCheckOverlay = _final: prev: {
    gnupg = prev.gnupg.overrideAttrs (_old: {
      doCheck = false;
    });
  };
in
[
  (final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      overlays = [ gnupgNoCheckOverlay ];
    };
  })
  gnupgNoCheckOverlay
  inputs.llm-agents.overlays.default
  inputs.nix-vscode-extensions.overlays.default
]
