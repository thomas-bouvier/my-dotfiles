# Minimal headless server configuration, for hosts that don't need a
# desktop environment (e.g. `morille`). It is a stripped-down variant of
# `configuration.nix` keeping the common subset: locales, shell, Nix
# settings and a small set of system packages.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./networking.nix
    ./tailscale.nix
  ];

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "fr_FR.UTF-8/UTF-8"
    ];
  };

  # Shell
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  # Nix settings
  nix.settings = {
    # Enable the Flakes feature and the accompanying new nix command-line tool
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-substituters = [
      "https://cache.nixos.org"
      "https://cache.nixos-cuda.org"
      "https://cache.flox.dev"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];

    # Optimise the store after each and every build (for the built path)
    auto-optimise-store = true;
  };

  # Garbage collect up to 1GiB whenever there is less than 512 MiB left
  nix.extraOptions = ''
    min-free = ${toString (512 * 1024 * 1024)}
    max-free = ${toString (1024 * 1024 * 1024)}
  '';

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      curl
      htop
      vim
      tmux
      zsh
      git
      tailscale
      wget
      util-linux
      dosfstools
      exfatprogs
      file
      usbutils
      openssl
    ];
  };

  programs.ssh.startAgent = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older
  # NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean that your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected the changes that it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
