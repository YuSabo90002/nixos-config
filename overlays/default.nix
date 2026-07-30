{ inputs }:
[
  (final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  })
  inputs.llm-agents.overlays.shared-nixpkgs
  inputs.nix-vscode-extensions.overlays.default
]
