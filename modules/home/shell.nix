{ ... }: {
  programs.nushell = {
    enable = true;
    settings = {
      show_banner = false;
      completions = {
        algorithm = "prefix";
        case_sensitive = false;
        quick = true;
        partial = true;
      };
    };
    shellAliases = {
      ll = "ls -l";
      la = "ls -a";
      lla = "ls -la";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      format = builtins.concatStringsSep "" [
        "[](fg:#A6E22E)"
        "$directory"
        "[](fg:#A6E22E bg:#AE81FF)"
        "$git_branch"
        "$git_status"
        "[](fg:#AE81FF bg:#66D9EF)"
        "$nix_shell"
        "[](fg:#66D9EF bg:#FD971F)"
        "$cmd_duration"
        "[](fg:#FD971F)"
        " $character"
      ];
      directory = {
        format = "[ $path ]($style)";
        style = "bold bg:#A6E22E fg:#272822";
        truncation_length = 3;
      };
      git_branch = {
        format = "[ $symbol$branch ]($style)";
        style = "bold bg:#AE81FF fg:#272822";
        symbol = " ";
      };
      git_status = {
        format = "[$all_status$ahead_behind]($style)";
        style = "bg:#AE81FF fg:#272822";
      };
      nix_shell = {
        format = "[ $symbol$state ]($style)";
        style = "bold bg:#66D9EF fg:#272822";
        symbol = " ";
      };
      cmd_duration = {
        format = "[ 󰔟 $duration ]($style)";
        style = "bold bg:#FD971F fg:#272822";
        min_time = 2000;
      };
      character = {
        success_symbol = "[➜](bold #A6E22E)";
        error_symbol = "[✗](bold #F92672)";
      };
    };
  };
}
