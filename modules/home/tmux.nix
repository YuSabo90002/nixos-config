{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    prefix = "C-a";
    escapeTime = 0;
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    historyLimit = 50000;
    extraConfig = ''
      # カレントディレクトリを引き継いで分割
      bind '"' split-window -v -c "#{pane_current_path}"
      bind '%' split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
    '';
    plugins = with pkgs.tmuxPlugins; [
      yank
      resurrect
      continuum
    ];
  };
}
