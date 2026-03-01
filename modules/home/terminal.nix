{ pkgs, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      terminal.shell = {
        program = "${pkgs.nushell}/bin/nu";
      };
      window = {
        padding = { x = 8; y = 8; };
        dynamic_padding = true;
        opacity = 0.85;
      };
      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        bold = { family = "JetBrainsMono Nerd Font"; style = "Bold"; };
        size = 13.0;
      };
      cursor = {
        style = { shape = "Block"; blinking = "On"; };
        blink_interval = 500;
      };
      scrolling = {
        history = 10000;
      };
      colors = {
        primary = {
          background = "#272822";
          foreground = "#F8F8F2";
        };
        normal = {
          black   = "#272822";
          red     = "#F92672";
          green   = "#A6E22E";
          yellow  = "#F4BF75";
          blue    = "#66D9EF";
          magenta = "#AE81FF";
          cyan    = "#A1EFE4";
          white   = "#F8F8F2";
        };
        bright = {
          black   = "#75715E";
          red     = "#F92672";
          green   = "#A6E22E";
          yellow  = "#F4BF75";
          blue    = "#66D9EF";
          magenta = "#AE81FF";
          cyan    = "#A1EFE4";
          white   = "#F9F8F5";
        };
      };
    };
  };
}
