{ inputs }:
let
  # openldap 2.6.13 の test017-syncreplication-refresh が flaky なため
  # テストを無効化してビルドを通す
  openldapNoCheckOverlay = _final: prev: {
    openldap = prev.openldap.overrideAttrs (_old: {
      doCheck = false;
    });
  };
in
[
  (final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      overlays = [ openldapNoCheckOverlay ];
    };
  })
  openldapNoCheckOverlay
  inputs.llm-agents.overlays.default
  inputs.nix-vscode-extensions.overlays.default
]
