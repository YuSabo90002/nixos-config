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

    # Tailscale SSH。tailnet の ACL で認証するため authorized_keys の管理が不要。
    # tailscaled が tailnet 側の 22 番を netstack で終端するので、通常の sshd は
    # tailnet からは経由されず LAN/localhost 用のフォールバックとして残る。
    # extraSetFlags は `tailscale set` を叩く tailscaled-set.service を生やす
    # (extraUpFlags は authKeyFile 併用時しか効かないためこちらを使う)。
    #
    # --operator は `tailscale up` / `down` を root 以外から叩けるようにする。
    # AGS の StatusPanel から接続をトグルするために必要。指定したユーザーは
    # tailscaled をほぼ全面的に操作できる (exit node 変更やログアウトも含む) が、
    # yuta は wheel なので sudo で同じことができ、権限上の実質的な差はない。
    extraSetFlags = [ "--ssh" "--operator=yuta" ];
  };

  # tailscale0 は TUN なので networking.nix の Type=ether/wlan にはマッチせず、
  # モジュール側の 50-tailscale (Unmanaged=true) で systemd-networkd の管理外に
  # なる。MagicDNS は既に有効な services.resolved が受け持つ。
}
