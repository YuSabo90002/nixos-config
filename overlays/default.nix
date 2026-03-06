{ inputs }:
[
  (final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  })
  inputs.fenix.overlays.default
  # nyxt 4.0.0 (nixpkgs PR #491363 がまだdraftのため自前で上書き)
  (final: _prev: {
    nyxt = final.callPackage ../packages/nyxt.nix { };
  })
  inputs.llm-agents.overlays.default
  inputs.nix-vscode-extensions.overlays.default
]
