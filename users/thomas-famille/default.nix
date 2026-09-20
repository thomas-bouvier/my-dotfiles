{
  config,
  pkgs,
  my-secrets,
  ...
}:

let
  secretsPath = builtins.toString my-secrets;
in
{
  imports = [
    (import ../thomas/atuin.nix {
      inherit config pkgs;
      secretsPath = secretsPath;
    })
    ../thomas/konsole.nix
    ../thomas/librewolf.nix
    ../thomas/plasma.nix
    (import ../thomas/ssh.nix {
      inherit config;
      secretsPath = secretsPath;
    })
    ../thomas/zsh.nix
  ];

  # Configure sops location
  # https://github.com/Mic92/sops-nix?tab=readme-ov-file#use-with-home-manager
  sops = {
    defaultSopsFile = "${secretsPath}/secrets/secrets.sops.yaml";
    defaultSopsFormat = "yaml";

    age = {
      keyFile = "/home/thomas/.config/sops/age/keys.txt";
    };
  };

  # Stylix configuration for user-specific wallpaper
  stylix = {
    image = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/thomas-bouvier/wallpapers/main/mont-saint-michel.jpg";
      sha256 = "sha256-IVcBW3Cd2TMyvGPtB88pyLeeNFt1jkxGWssQ9yuhFdQ=";
    };
  };

  home = {
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    username = "thomas";
    homeDirectory = "/home/thomas";

    # Emacs configuration
    file.".emacs.d/init.el".source = ../../emacs/init.el;
    file.".emacs.d/early-init.el".source = ../../emacs/early-init.el;

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      # Everyday life
      localsend
      vlc
      kdePackages.kcalc
      kdePackages.kcharselect
      kdePackages.kfind
      kdePackages.filelight
      kdePackages.kompare
      libreoffice-qt6-fresh

      # Command line
      neovim
      eza
      age
      sops
      jq
      unrar
      nh

      # Theme
      nordic
      (whitesur-icon-theme.override {
        alternativeIcons = true;
        boldPanelIcons = true;
      })
    ];

    sessionVariables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "24.05"; # Please read the comment before changing.
  };

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

  programs.git = {
    enable = true;
    signing.format = "openpgp";

    settings = {
      user.name = "Thomas Bouvier";
      user.email = "contact@thomas-bouvier.io";

      init.defaultBranch = "main";
      push.autoSetupRemote = true;

      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
