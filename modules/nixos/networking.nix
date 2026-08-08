{ config, lib, ... }:
let
  # RA を蹴って IPv4 のみにする設定。
  suppressed = {
    DHCP = "ipv4";
    IPv6AcceptRA = false;
    LinkLocalAddressing = "ipv4";
  };
  normal = {
    DHCP = "yes";
  };

  # ホスト全体で抑制するか (据え置き機向け)
  v6 = if config.my.suppressIPv6 then suppressed else normal;

  suppressSSIDs = config.my.suppressIPv6OnSSIDs;
in
{
  options.my.suppressIPv6 = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      IPv6 を全面的に無効化するか。

      自宅回線は ISP が IPv4 のみ契約だが NTT 網内 IPv6 (240b::/20) が RA で流入し、
      疎通しない IPv6 先に SYN を撃ち続けてハングする。据え置き機ではこれを true に
      して回避している。

      持ち出す機体で true にすると、外出先の正常な IPv6 網でも v6 が一切使えなく
      なるため false のままにすること。代わりに my.suppressIPv6OnSSIDs を使う。
    '';
  };

  options.my.suppressIPv6OnSSIDs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "Buffalo-17B8" ];
    description = ''
      この SSID に繋いでいるときだけ IPv6 を抑制する。持ち出す機体で、自宅など
      特定の回線でだけ IPv6 が壊れている場合に使う (my.suppressIPv6 の
      全ホスト版に対する、ネットワーク単位版)。

      systemd-networkd の [Match] SSID= で実現しており、生成する .network の
      ファイル名を汎用ルールより手前 (24- < 25-) にして優先させる。
      SSID は空白区切りで並べる仕様のため、空白を含む SSID は指定できない。
    '';
  };

  config = {
    networking.useNetworkd = true;
    systemd.network.enable = true;

    systemd.network.networks."20-wired" = {
      matchConfig.Type = "ether";
      networkConfig = v6;
      dhcpV4Config.RouteMetric = 100;
    };

    # networkd は最初にマッチした .network だけを適用し、ファイル名の辞書順で
    # 探すので、SSID 限定のこれを汎用の 25- より手前に置く。
    systemd.network.networks."24-wireless-suppress-ipv6" =
      lib.mkIf (suppressSSIDs != [ ]) {
        matchConfig = {
          Type = "wlan";
          SSID = lib.concatStringsSep " " suppressSSIDs;
        };
        networkConfig = suppressed;
        dhcpV4Config.RouteMetric = 600;
      };

    systemd.network.networks."25-wireless" = {
      matchConfig.Type = "wlan";
      networkConfig = v6;
      dhcpV4Config.RouteMetric = 600;
    };

    networking.wireless.iwd = {
      enable = true;
      settings = {
        General = {
          # アドレス設定は networkd 側でやるので iwd には触らせない
          EnableNetworkConfiguration = false;
        };
        Settings = {
          AutoConnect = true;
        };
      };
    };

    services.resolved.enable = true;

    networking.firewall.allowedTCPPorts = [ 1420 1421 ];
  };
}
