{ lib, buildNpmPackage, fetchurl, makeWrapper, nodejs, tmux, git }:

buildNpmPackage rec {
  pname = "dmux";
  version = "5.6.3";

  src = fetchurl {
    url = "https://registry.npmjs.org/dmux/-/dmux-${version}.tgz";
    hash = "sha256-mUrqDCxrLtssEecr4ZAP6VvfTvzLTJMoE1OH5rDU4e4=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-mlIw2jjBc8kThKLwEI6HGtRTC7USK+T7Rg9+yhxtoFs=";

  dontNpmBuild = true;
  npmFlags = [ "--omit=dev" "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/dmux
    cp -r . $out/lib/node_modules/dmux/

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/dmux \
      --add-flags $out/lib/node_modules/dmux/dist/index.js \
      --prefix PATH : ${lib.makeBinPath [ nodejs tmux git ]}

    runHook postInstall
  '';

  meta = {
    description = "Tmux pane manager with AI agent integration for parallel development workflows";
    homepage = "https://github.com/standardagents/dmux";
    license = lib.licenses.mit;
    mainProgram = "dmux";
    platforms = lib.platforms.unix;
  };
}
