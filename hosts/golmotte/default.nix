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

    # We need printing drivers
    ../../system/printing.nix

    # Users
    ../../users/thomas-famille.nix
    ../../users/famille.nix

    # Partitioning
    ./disko-configuration.nix
  ];

  networking.hostName = "golmotte";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # https://discourse.nixos.org/t/nixos-rebuild-remote-deployments-non-root-pam/50477
  security.pam = {
    # Enable the ssh-agent of a user to be used to authenticate them.
    sshAgentAuth.enable = true;
    # Allow ssh-agent authentication to give authorization to use sudo.
    services.sudo.sshAgentAuth = true;
  };

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;

    initrd.availableKernelModules = [
      "xhci_pci"
      "usb_storage"
      "usbhid"
    ];
    initrd.kernelModules = [ ];

    kernelModules = [ ];
    extraModulePackages = [ ];
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

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
