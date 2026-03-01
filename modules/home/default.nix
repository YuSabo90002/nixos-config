{ pkgs, inputs, ... }: {
  imports = [
    inputs.ags.homeManagerModules.default
    ./hyprland.nix
    ./xdg.nix
    ./shell.nix
    ./terminal.nix
    ./editors.nix
  ];

  home = {
    username = "yuta";
    homeDirectory = "/home/yuta";
    stateVersion = "25.11";
  };

  home.packages = with pkgs; [
    firefox
    ripgrep
    fd
    btop
    wofi
    grim
    slurp
    wl-clipboard
    swww
    unstable.claude-code
    unstable.discord
    pavucontrol
    winboat
    unstable.gh
    unstable.uv
    unstable.volta
  ];

  programs.ags = {
    enable = true;
    configDir = ../../ags;
    extraPackages = with inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}; [
      hyprland
      wireplumber
      mpris
      notifd
      tray
    ];
  };

  programs.git = {
    enable = true;
    settings = {
      user.Name = "yuta";
      user.email = "yusabo90002@gmail.com";
      core.editor = "nvim";
    };
  };

  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";
}
