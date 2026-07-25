{ ... }: {
  services.tailscale = {
    enable = true;

    # UDP 41641 を開けて NAT 越しでも直接接続 (P2P) を成立しやすくする。
    # 塞いだままだと DERP 中継経由になり遅延・帯域が落ちる。
    openFirewall = true;

    # exit node / サブネットルータの「利用側」設定。
    # reverse path filtering が loose になり、exit node 経由の戻りパケットが
    # 落ちなくなる。自分が exit node として「提供」する場合は "both" にして
    # `tailscale up --advertise-exit-node` を実行する。
    useRoutingFeatures = "client";
  };

  # tailscale0 は TUN なので networking.nix の Type=ether/wlan にはマッチせず、
  # モジュール側の 50-tailscale (Unmanaged=true) で systemd-networkd の管理外に
  # なる。MagicDNS は既に有効な services.resolved が受け持つ。
}
