# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./apptainer.nix
    ./bluetooth.nix
    ./stylix.nix
    ./tailscale.nix
    ./networking.nix
    ./partition-manager.nix
  ];

  # Enable system modules
  bluetooth.enable = true;

  stylix = {
    enable = true;
    #targets.qt.platform = "kde6";
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "fr_FR.UTF-8/UTF-8"
    ];
  };

  services = {
    # KDE Plasma 6
    displayManager = {
      defaultSession = "plasma";
      sddm.enable = true;
      sddm.wayland.enable = true;
    };

    desktopManager.plasma6.enable = true;

    # Enable CUPS to print documents.
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
    printing = {
      enable = true;
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
      browsing = true;
      defaultShared = true;
    };

    # Enable sound and camera.
    pipewire.enable = true;

    # Enable touchpad support (enabled default in most desktopManager).
    libinput.enable = true;
  };

  # Kwallet
  security.pam.services.sddm.enableKwallet = true;
  security.pam.services.kdewallet.enableKwallet = true;

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
      vim
      zsh
      git
      tailscale
      wget
      util-linux
      dosfstools
      exfatprogs
      dracut
      file
      usbutils
      pciutils
      efibootmgr
      openssl
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  nixpkgs.config = {
    # Combined predicate: keep the legacy name whitelist, and also accept
    # packages whose licenses are CUDA-related EULAs.
    allowUnfreePredicate =
      let
        ensureList = x: if builtins.isList x then x else [ x ];
        legacyNames = [
          "cnijfilter2"
          "unrar"
          # Nvidia
          "nvidia-x11"
          "nvidia-settings"
          "nvidia-kernel-modules"
          "cuda_cccl"
          "cuda_cudart"
          "cuda_nvcc"
          "nsight_systems"
          "nsight_compute"
          # Apple
          "apple_cursor"
          "obsidian"
          # Crap by Intel for cameras
          "ipu6-camera-bins"
          "ipu6-camera-bins-unstable"
          "ivsc-firmware"
          "ivsc-firmware-unstable"
        ];
      in
      package:
      (builtins.elem (lib.getName package) legacyNames)
      || builtins.all (
        license:
        license.free
        || builtins.elem license.shortName [
          "CUDA EULA"
          "cuDNN EULA"
        ]
      ) (ensureList package.meta.license);
  };

  programs.ssh.startAgent = true;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
