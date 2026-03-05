{ inputs }:
[
  (final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  })
  inputs.fenix.overlays.default
  (final: _prev: {
    specify-cli = final.callPackage ../packages/specify-cli.nix { };
  })
  inputs.llm-agents.overlays.default
]
