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
    # We need virtualisation capabilities
    ../../system/virtualisation.nix
    # We need code-on-incus (coi)
    ../../system/coi.nix
    # Enable Guix on this machine :)
    ../../system/guix.nix

    # Users
    ../../users/thomas-work.nix
  ];

  networking.hostName = "cladosporium";

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = false;
        efiInstallAsRemovable = false;

        extraEntries = ''
          menuentry "Ubuntu" {
            search --set=root --fs-uuid 1d744e85-8071-49ad-88af-f589dd84a2c2
            linux /vmlinuz-7.0.0-22-generic root=UUID=17e7d813-4976-408c-a1fd-ed4f937446ac ro quiet splash
            initrd /initrd.img-7.0.0-22-generic
          }
        '';
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };

    initrd.luks.devices."dm-lvm" = {
      device = "/dev/disk/by-uuid/c39eb9dc-607a-4579-9d37-dc8381903e8c";
      preLVM = true;
    };

    initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "usb_storage"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];
    initrd.kernelModules = [ "dm-snapshot" ];

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    # Use the latest kernel
    kernelPackages = pkgs.linuxPackages_latest;
  };

  fileSystems."/" = {
    device = "/dev/mapper/vg0-nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1d744e85-8071-49ad-88af-f589dd84a2c2";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/6D89-D11D";
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

  hardware = {
    ipu6 = {
      enable = true;
      platform = "ipu6epmtl"; # mtl stands for Meteor Lake
    };
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0f0u10.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.npu.enable = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
