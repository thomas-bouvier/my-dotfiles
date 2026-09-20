{
  config,
  pkgs,
  my-secrets,
  ...
}:

{
  imports = [
    ./librewolf.nix
    ./plasma.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "famille";
  home.homeDirectory = "/home/famille";

  home.language = {
    base = "fr_FR.utf8";
  };

  # Stylix configuration for user-specific wallpaper
  stylix = {
    image = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/thomas-bouvier/wallpapers/main/20190721_122217.jpg";
      sha256 = "sha256-8VYuc3CP4gnuwTvogvIK6qvi4R+xtIpbb41RLsK53gA=";
    };
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # Everyday life
    localsend
    vlc
    kdePackages.kcalc
    kdePackages.kcharselect
    kdePackages.kfind
    kdePackages.filelight
    kdePackages.kompare
    libreoffice-qt

    # Theme
    nordic
  ];

  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "librewolf.desktop";
        "x-scheme-handler/http" = "librewolf.desktop";
        "x-scheme-handler/https" = "librewolf.desktop";
        "x-scheme-handler/about" = "librewolf.desktop";
        "x-scheme-handler/unknown" = "librewolf.desktop";
      };
    };

    configFile."mimeapps.list".force = true;
  };

  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.
}
