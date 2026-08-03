{ lib, ... }:
let
  # 画像ビューワ: swayimg (swayimg.desktop の MimeType と同じ一覧)
  imageMimeTypes = [
    "image/avif"
    "image/bmp"
    "image/gif"
    "image/heif"
    "image/jpeg"
    "image/jpg"
    "image/jxl"
    "image/pbm"
    "image/pjpeg"
    "image/png"
    "image/svg+xml"
    "image/tiff"
    "image/webp"
    "image/x-bmp"
    "image/x-exr"
    "image/x-png"
    "image/x-portable-anymap"
    "image/x-portable-bitmap"
    "image/x-portable-graymap"
    "image/x-portable-pixmap"
    "image/x-targa"
    "image/x-tga"
  ];

  # ドキュメントビューワ: zathura。プラグインごとに .desktop が分かれている。
  # 各 .desktop が申告する MimeType のうち、画像系 (mupdf の image/*) と
  # 汎用アーカイブ・ディレクトリ (cb の application/zip, x-tar, inode/directory 等) は
  # swayimg / ouch / ファイルマネージャの担当なので意図的に除いてある。
  documentHandlers = {
    "org.pwmt.zathura-pdf-mupdf.desktop" = [
      "application/pdf"
      "application/oxps"
      "application/epub+zip"
      "application/x-fictionbook"
      "application/x-mobipocket-ebook"
    ];
    "org.pwmt.zathura-djvu.desktop" = [
      "image/vnd.djvu"
      "image/vnd.djvu+multipage"
    ];
    "org.pwmt.zathura-ps.desktop" = [
      "application/postscript"
      "application/eps"
      "application/x-eps"
      "image/eps"
      "image/x-eps"
    ];
    "org.pwmt.zathura-cb.desktop" = [
      "application/x-cbr"
      "application/x-cbz"
      "application/x-cb7"
      "application/x-cbt"
    ];
  };
in {
  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.genAttrs imageMimeTypes (_: "swayimg.desktop")
      // lib.concatMapAttrs (desktop: mimes: lib.genAttrs mimes (_: desktop)) documentHandlers
      // {
      # ファイルマネージャ: Alacritty で指定フォルダを開く
      "inode/directory" = "alacritty-folder.desktop";

      # ブラウザ (Zen Twilight)
      "x-scheme-handler/http" = "zen-twilight.desktop";
      "x-scheme-handler/https" = "zen-twilight.desktop";
      "x-scheme-handler/chrome" = "zen-twilight.desktop";
      "text/html" = "zen-twilight.desktop";
      "application/x-extension-htm" = "zen-twilight.desktop";
      "application/x-extension-html" = "zen-twilight.desktop";
      "application/x-extension-shtml" = "zen-twilight.desktop";
      "application/xhtml+xml" = "zen-twilight.desktop";
      "application/x-extension-xhtml" = "zen-twilight.desktop";
      "application/x-extension-xht" = "zen-twilight.desktop";

      # Claude Code URL ハンドラ
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = false; # 26.05+ の新デフォルト。XDG_*_DIR 環境変数は出さず user-dirs.dirs のみ生成
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
    music = "$HOME/Music";
    desktop = "$HOME/Desktop";
  };

  # xdg-open でフォルダを Alacritty で開くためのエントリ
  xdg.desktopEntries.alacritty-folder = {
    name = "Alacritty (Folder)";
    comment = "Open a folder in Alacritty";
    exec = "alacritty --working-directory %f";
    icon = "Alacritty";
    terminal = false;
    type = "Application";
    categories = [ "System" "TerminalEmulator" "Utility" ];
    mimeType = [ "inode/directory" ];
    settings = {
      NoDisplay = "true";
    };
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
