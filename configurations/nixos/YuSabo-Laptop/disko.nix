# 既にこのレイアウトで切ってあるディスクをそのまま宣言する (再作成はしない)。
# 移行元: ラップトップの ~/nix-config/nixos/disko-config.nix
#
# 実機の実サイズと一致していることを確認済み:
#   p1 1G vfat / p2 約444G ext4 / p3 32G swap
{ ... }:
{
  disko.devices = {
    disk = {
      # この属性名は GPT のパーティションラベル (disk-<名前>-<パーティション名>) に
      # そのまま入り、生成される fileSystems.device が by-partlabel でそれを指す。
      # 実機は移行元の名前 "vdb" で既に焼かれているため、Yuta-PC に合わせて "main"
      # に改名すると / が見つからず起動しなくなる。実機のラベルに合わせること。
      #   実機: disk-vdb-ESP / disk-vdb-root / disk-vdb-plainSwap
      vdb = {
        # /dev/nvme0n1 ではなく by-id を使う。NVMe の番号は付け替えで変わりうる。
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB512HBJQ-000L7_S4ENNF2N156660";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              # 末尾 32G を swap に残す
              end = "-32G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            plainSwap = {
              size = "100%";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
          };
        };
      };
    };
  };
}
