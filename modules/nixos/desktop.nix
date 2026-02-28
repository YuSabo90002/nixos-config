{ pkgs, lib, ... }: {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  programs.uwsm.enable = true;

  # グリーター(regreet)をHyprland上で起動し、DP-2を無効にする
  programs.regreet.enable = true;
  services.greetd.settings.default_session.command = lib.mkForce
    "dbus-run-session ${pkgs.hyprland}/bin/start-hyprland -- -c /etc/greetd/hyprland.conf";
  environment.etc."greetd/hyprland.conf".text = ''
    monitor = DP-1, preferred, auto, 1
    monitor = DP-2, disable
    exec-once = ${lib.getExe pkgs.regreet}; hyprctl dispatch exit
    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
    }
  '';

  programs.steam = {
    enable = true;
    dedicatedServer.openFirewall = true;
    remotePlay.openFirewall = true;
  };

  # AMD GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
