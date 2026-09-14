# ComfyUI (ローカル画像生成) を RX 9070 XT (gfx1201) の ROCm で動かす。
#
# - comfyui は unstable にしか無いが、unstable の ROCm 版 torch は cache.nixos.org に
#   無い (ソースビルドは数時間)。stable (26.05) の pkgsRocm の torch/torchvision/torchaudio は
#   cache 済みなので、stable pkgsRocm の Python に unstable の comfyui 関連の式だけ持ち込む。
# - データ (models/ custom_nodes/ input/ output/ user/) は nixpkgs のパッチにより
#   ~/.local/share/comfyui。モデルはそこへ手で置く (巨大なので store には入れない)。
{
  flake,
  pkgs,
  lib,
  ...
}:
let
  unstableSrc = flake.inputs.nixpkgs-unstable;

  # stable に無い ComfyUI の依存 (unstable の pkgs/development/python-modules から持ち込む)
  missingPythonPackages = [
    "comfy-aimdo"
    "comfy-angle"
    "comfy-kitchen"
    "comfyui-embedded-docs"
    "comfyui-frontend-package"
    "comfyui-workflow-templates"
    "comfyui-workflow-templates-core"
    "comfyui-workflow-templates-json"
    "comfyui-workflow-templates-media-api"
    "comfyui-workflow-templates-media-assets-01"
    "comfyui-workflow-templates-media-image"
    "comfyui-workflow-templates-media-other"
    "comfyui-workflow-templates-media-video"
    "spandrel"
  ];

  # comfyui の package.nix が python3.override { packageOverrides } をするので
  # (packageOverrides は上書きで合成されない) pythonPackagesExtensions で足す。
  # 追加するだけなので torch 等の drv は pkgsRocm と同一のまま = cache に当たる。
  rocmPkgs = pkgs.pkgsRocm.extend (
    _final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (
          pyFinal: _pyPrev:
          lib.genAttrs missingPythonPackages (
            name: pyFinal.callPackage "${unstableSrc}/pkgs/development/python-modules/${name}" { }
          )
          // {
            # 上の式が meta.maintainers を引くためだけに受け取る引数
            inherit (pkgs.unstable) comfyui;
          }
        )
      ];
    }
  );

  comfyui = rocmPkgs.callPackage "${unstableSrc}/pkgs/by-name/co/comfyui/package.nix" {
    # package.nix が torch/triton を cudaPackages_13 で override する。ROCm では未使用だが
    # 別の値を渡すと drv が変わって cache を外すので、torch 自身が持つものを渡し直す。
    cudaPackages_13 = rocmPkgs.python3Packages.torch.cudaPackages;
  };

  comfyuiWrapped = pkgs.symlinkJoin {
    name = "comfyui-rocm-${comfyui.version}";
    paths = [ comfyui ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    # - RDNA3/4 の flash attention (aotriton) を有効化。MIOpen の初回チューニングで
    #   VAE デコードが長く止まるのを避ける。どちらも起動前に上書き可。
    # - DynamicVRAM (comfy-aimdo) は AMD だと ROCm 7.14 以上でしか使われない。それでも
    #   起動直後に aimdo を初期化しに行き、nixpkgs の torch は版数に "+rocm" が付かないので
    #   Nvidia 用の実装を読み込んでしまう。どうせ使われないので最初から切っておく。
    postBuild = ''
      wrapProgram $out/bin/comfyui \
        --set-default TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL 1 \
        --set-default MIOPEN_FIND_MODE FAST \
        --add-flags --disable-dynamic-vram
    '';
    inherit (comfyui) meta;
  };
in
{
  home-manager.users.yuta.home.packages = [ comfyuiWrapped ];
}
