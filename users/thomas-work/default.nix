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
    (import ../thomas/atuin.nix {
      inherit config pkgs;
      secretsPath = secretsPath;
    })
    ../thomas/konsole.nix
    (import ../thomas/opencode.nix {
      inherit config lib;
      secretsPath = secretsPath;
    })
    ../thomas/plasma.nix
    (import ../thomas/ssh.nix {
      inherit config;
      secretsPath = secretsPath;
    })
    ../thomas/vscode.nix
    ../thomas/zsh.nix

    # Specific Librewolf config
    ./librewolf.nix
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
      url = "https://raw.githubusercontent.com/thomas-bouvier/wallpapers/main/jz.jpg";
      sha256 = "sha256-N5XuOEgtToHEFtudmiKpJakESpEpVGUCW53p6X9LktY=";
    };
  };

  # Emacs daemon - starts automatically at login
  services.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
    client.enable = true;
    defaultEditor = true;
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
        mattermost-desktop
        thunderbird
        obsidian
        vlc
        kdePackages.kcalc
        kdePackages.kcharselect
        kdePackages.kfind
        kdePackages.filelight
        kdePackages.kompare
        kdePackages.partitionmanager
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
        binutils
        oras

        # Development
        python314
        basedpyright
        mypy
        uv
        go
        hugo
        marimo
        guix
        emacs-pgtk
        cudaPackages.nsight_systems
        gh

        # Virtualisation
        dive
        podman
        podman-compose
        apptainer

        # Research
        zotero
        texliveFull
        texstudio
        quarto

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
