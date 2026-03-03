{ pkgs, inputs, ... }: {
  imports = [
    inputs.nixvim.homeModules.default
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
    };
    highlightOverride = {
      Normal = { bg = "none"; };
      NonText = { bg = "none"; };
      SignColumn = { bg = "none"; };
      LineNr = { bg = "none"; };
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.unstable.vscode;
    profiles.default = {
      extensions = with pkgs.unstable.vscode-extensions; [
        ms-ceintl.vscode-language-pack-ja
        anthropic.claude-code
      ];
    };
  };
}
