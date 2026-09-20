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

    # We need Nvidia drivers
    ../../system/nvidia.nix
    # We need printing drivers
    ../../system/printing.nix
    # We need virtualisation capabilities
    ../../system/virtualisation.nix
    # We need code-on-incus (coi)
    ../../system/coi.nix

    # Users
    ../../users/thomas.nix
  ];

  networking.hostName = "bolet";

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    # Use the latest kernel
    kernelPackages = pkgs.linuxPackages_latest;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/ROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/NIX";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };

  fileSystems."/storage" = {
    device = "/dev/disk/by-label/STORAGE";
    fsType = "ext4";
    options = [
      "users"
      "nofail"
    ];
  };

  swapDevices = [
    {
      device = "/.swapfile";
    }
    {
      device = "/storage/swapfile2";
      size = 100 * 1024; # 100GB
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
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0f0u10.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
