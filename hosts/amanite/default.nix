{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../system/configuration.nix

    # We need virtualisation capabilities
    ../../system/virtualisation.nix
    # We need code-on-incus (coi)
    ../../system/coi.nix
    # We need printing drivers
    ../../system/printing.nix

    # Users
    ../../users/thomas.nix
  ];

  networking.hostName = "amanite";

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;

    initrd.availableKernelModules = [
      "usb_storage"
      "sdhci_pci"
    ];
    initrd.kernelModules = [ ];

    kernelModules = [ ];
    extraModulePackages = [ ];

    extraModprobeConfig = ''
      options hid_apple iso_layout=0
    '';
  };

  hardware.asahi = {
    enable = true;
    peripheralFirmwareDirectory = ./firmware;
  };

  #hardware.graphics.package =
  # Workaround for Mesa 26.0.5 regression
  # https://github.com/nix-community/nixos-apple-silicon/issues/447
  # https://gitlab.freedesktop.org/mesa/mesa/-/work_items/15288
  #  (import (fetchTarball {
  #    url = "https://github.com/NixOS/nixpkgs/archive/df26bc59d3c7cd52e4005dfe9843b1e7b0554de1.tar.gz";
  #    sha256 = "sha256-Tmp0nu2JTMHHOuV20ElkPduB0IuZaG3pBjrYPDx79u8=";
  #  }) { localSystem = pkgs.stdenv.hostPlatform; }).mesa;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/bfa5b39e-5d73-4ec5-ba59-b9e6200a2162";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/80E1-1516";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 60 * 1024; # 60GB
    }
  ];
  zramSwap = {
    enable = true;
    memoryPercent = 90;
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
