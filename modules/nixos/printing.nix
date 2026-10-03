{ pkgs, ... }: {
  # 自宅 LAN の Brother DCP-L2540DW (モノクロレーザー複合機)。
  # 機種自体は IPP Everywhere (driverless) にも対応しているが、lpadmin の
  # `-m everywhere` は登録時にプリンタへ問い合わせるため、ラップトップを外に
  # 持ち出した状態で switch すると ensure-printers が失敗する。オフラインでも
  # 登録できるよう、オープンソースのドライバ brlaser の PPD を使う。
  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  hardware.printers = {
    ensureDefaultPrinter = "Brother_DCP-L2540DW";
    ensurePrinters = [{
      name = "Brother_DCP-L2540DW";
      description = "Brother DCP-L2540DW";
      location = "自宅";
      # ホスト名は無線 LAN 側のノード名 (BRW + MAC)。mDNS で解決するので
      # DHCP で IP が変わっても追従する (networking.nix で mDNS を有効化済み)。
      # brlaser の出力は Brother 独自のラスタなので、生データをそのまま
      # 流せる JetDirect (9100) を使う。
      deviceUri = "socket://BRWE89EB4310576.local:9100";
      model = "drv:///brlaser.drv/brl2540d.ppd";
      ppdOptions = {
        PageSize = "A4";
        Duplex = "None";
      };
    }];
  };
}
