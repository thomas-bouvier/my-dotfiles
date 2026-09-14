{
  config,
  pkgs,
  lib,
  my-secrets,
  ...
}:

let
  secretsPath = builtins.toString my-secrets;
in
{
  imports = [
    (import ./atuin.nix {
      inherit config pkgs;
      secretsPath = secretsPath;
    })
    ./konsole.nix
    (import ./opencode.nix {
      inherit config lib pkgs;
      secretsPath = secretsPath;
    })
    ./librewolf.nix
    ./plasma.nix
    (import ./ssh.nix {
      inherit config;
      secretsPath = secretsPath;
    })
    ./vscode.nix
    ./zsh.nix
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
  #stylix = {
  #  image = pkgs.fetchurl {
  #    url = "https://raw.githubusercontent.com/thomas-bouvier/wallpapers/main/ecmwf.png";
  #    sha256 = "sha256-m9DzW+B5As/FemMObk2Kll+Nf2B3uYaHD8EXJl0w+pU=";
  #  };
  #};

  # Emacs daemon - starts automatically at login
  services.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
    client.enable = true;
    defaultEditor = true;
  };

  # Earth View - random Google Earth wallpapers
  services.earth-view = {
    enable = true;
    interval = "24h";
    imageDirectory = ".earth-view";
    display = "fill";
    enableXinerama = true;
    autoStart = false;
    gc = {
      enable = false;
      keep = 10;
      interval = null;
      sizeThreshold = "0";
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
    packages =
      with pkgs;
      [
        # Everyday life
        anki
        thunderbird
        obsidian
        localsend
        vlc
        signal-desktop
        kdePackages.kcalc
        kdePackages.kcharselect
        kdePackages.kfind
        kdePackages.filelight
        kdePackages.kompare
        kdePackages.kamoso
        kdePackages.krecorder
        libreoffice-qt6-fresh
        chromium

        # Command line
        curl
        neovim
        eza
        age
        htop
        sops
        jq
        unrar
        nh
        wl-clipboard
        git-filter-repo
        ripgrep
        rclone
        scaleway-cli
        step-cli
        binutils
        oras

        # Development
        python314
        nodejs
        basedpyright
        mypy
        uv
        go
        hugo
        marimo
        emacs-pgtk
        cudaPackages.nsight_systems
        gh
        code-cursor
        cursor-cli

        # Virtualisation
        dive
        podman
        podman-compose
        apptainer
        opentofu

        # Android
        android-tools

        # Research
        zotero
        texliveFull
        texstudio
        quarto

        # Graphics
        inkscape
        gimp
        kdePackages.kdenlive
        qgis

        # Entertainment
        qbittorrent
        ryubing
        luanti
        nicotine-plus
        gpodder
        mixxx

        # Audio
        kdePackages.elisa
        yt-dlp
        audacity
        ffmpeg

        # Theme
        nordic
        (whitesur-icon-theme.override {
          alternativeIcons = true;
          boldPanelIcons = true;
        })
      ]
      ++ (
        if stdenv.hostPlatform.system != "aarch64-linux" then
          [
            # List packages not compatible with aarch64 here
          ]
        else
          [ ]
      );

    sessionVariables = {
      EDITOR = lib.mkForce "vim";
      VISUAL = lib.mkForce "vim";
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
