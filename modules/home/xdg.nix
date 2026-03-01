{ ... }: {
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
    music = "$HOME/Music";
    desktop = "$HOME/Desktop";
  };

  # steamwebhelperがDRI_PRIME=1でクラッシュする問題の回避
  # https://github.com/ValveSoftware/steam-for-linux/issues/9383
  xdg.desktopEntries.steam = {
    name = "Steam";
    comment = "Application for managing and playing games on Steam";
    exec = "steam %U";
    icon = "steam";
    terminal = false;
    type = "Application";
    categories = [ "Network" "FileTransfer" "Game" ];
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
  };

  xdg.configFile = {
    "fcitx5/config" = {
      force = true;
      text = ''
        [Hotkey/TriggerKeys]
        0=Control+Shift+T
      '';
    };
    "fcitx5/profile" = {
      force = true;
      text = ''
        [Groups/0]
        Name=Default
        Default Layout=us
        DefaultIM=skk

        [Groups/0/Items/0]
        Name=skk
        Layout=

        [Groups/0/Items/1]
        Name=keyboard-us
        Layout=

        [GroupOrder]
        0=Default
      '';
    };
  };
}
