{ ... }: {
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # Docker の veth/bridge を除外するため、物理NICのみにマッチさせる
  systemd.network.networks."20-wired" = {
    matchConfig = {
      Type = "ether";
      Name = "!veth* !docker* !br-*";
    };
    networkConfig.DHCP = "yes";
    dhcpV4Config.RouteMetric = 100;
  };

  systemd.network.networks."25-wireless" = {
    matchConfig.Type = "wlan";
    networkConfig.DHCP = "yes";
    dhcpV4Config.RouteMetric = 600;
  };

  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = false;
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };

  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    fallbackDns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
}
