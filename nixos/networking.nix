{ ... }: {
  networking.useNetworkd = true;
  systemd.network.enable = true;

  systemd.network.networks."20-wired" = {
    matchConfig.Type = "ether";
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
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      FallbackDNS = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };
}
