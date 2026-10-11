{
  config,
  lib,
  pkgs,
  my-secrets,
  ...
}:

let
  secretsPath = builtins.toString my-secrets;
in
{
  # Reuse the desktop-agnostic modules of the `thomas` profile
  imports = [
    (import ../thomas/atuin.nix {
      inherit config pkgs;
      secretsPath = secretsPath;
    })
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

  home = {
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    username = "thomas";
    homeDirectory = "/home/thomas";

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      # Command line
      neovim
      eza
      age
      sops
      jq
      nh
      ripgrep

      # Virtualisation
      dive
      podman
      podman-compose
    ];

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

  programs.git = {
    enable = true;
    signing.format = "openpgp";

    # Globally ignored in every repository (via core.excludesFile).
    ignores = [
      ".local/"
      ".claude/"
      ".codex/"
    ];

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
