{ ... }: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

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
        "$directory"
        "$git_branch"
        "$git_status"
        "$nix_shell"
        "$cmd_duration"
        "\n$character"
      ];

      directory = {
        format = "[](fg:#A6E22E)[  $path ](bold bg:#A6E22E fg:#272822)[](fg:#A6E22E)";
        truncation_length = 3;
      };

      git_branch = {
        format = " [](fg:#AE81FF)[  $branch ](bold bg:#AE81FF fg:#272822)[](fg:#AE81FF)";
      };

      git_status = {
        format = "( [$all_status$ahead_behind](bold fg:#F92672))";
      };

      nix_shell = {
        format = " [](fg:#66D9EF)[  $state ](bold bg:#66D9EF fg:#272822)[](fg:#66D9EF)";
      };

      cmd_duration = {
        format = " [](fg:#FD971F)[ 󰔗 $duration ](bold bg:#FD971F fg:#272822)[](fg:#FD971F)";
        min_time = 2000;
      };

      character = {
        success_symbol = "[❯](bold #A6E22E)";
        error_symbol = "[❯](bold #F92672)";
      };
    };
  };
}
