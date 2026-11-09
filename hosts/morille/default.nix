{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    # SD card image, to flash on the Raspberry Pi. Build it with:
    # $ nix build .#nixosConfigurations.morille.config.system.build.sdImage
    # The image comes pre-partitioned (Firmware + ext4 root) and grows the
    # root partition on first boot.
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")

    # Headless server profile (no desktop environment)
    ../../system/server-configuration.nix

    # We need virtualisation capabilities (podman)
    ../../system/virtualisation.nix

    # Users
    ../../users/thomas-server.nix

    # Home Assistant container
    ./home-assistant.nix
  ];

  # --- Boot -----------------------------------------------------------------
  #
  # The Pi firmware boots the kernel directly from the FAT partition —
  # the Raspberry Pi OS native path. No U-Boot, no extlinux: the
  # `nixos-hardware` firmware modules stage the GPU boot code, device
  # trees and overlays; we stage the kernel, the initrd and the kernel
  # command line.

  hardware.raspberry-pi.configtxt.file = pkgs.writeText "config.txt" ''
    kernel=Image
    initramfs initrd followkernel
    arm_64bit=1
    arm_boost=1
    enable_uart=1
    disable_overscan=1
    display_auto_detect=1
  '';

  # Stage only what the `nixos-hardware` firmware script (which also
  # defines this option with `mkForce` and runs first) does not. Its own
  # files (GPU boot code, device trees, overlays, config.txt) are copied
  # read-only from the Nix store, so re-copying them here would fail.
  sdImage.populateFirmwareCommands = lib.mkForce ''
    cp ${config.system.build.toplevel}/kernel firmware/Image
    cp ${config.system.build.toplevel}/initrd firmware/initrd
    echo "init=${config.system.build.toplevel}/init $(cat ${config.system.build.toplevel}/kernel-params)" > firmware/cmdline.txt
  '';

  # The kernel and the initrd live on the FAT partition: give it room.
  sdImage.firmwareSize = 512;

  # Scripted initrd was removed from nixpkgs: stage 1 is systemd-only.
  # Keep the module list minimal — `sd-image-aarch64` force-enables
  # `hardware.enableAllHardware`, whose generic aarch64 list includes
  # Rockchip's `dw-hdmi`, a module the RPi kernel does not provide and
  # which breaks the initrd module closure. In particular `mmc_block`
  # (stage 1 must see the SD card's root partition) and `genet` (Pi 4
  # ethernet) are required.
  boot.initrd.availableKernelModules = lib.mkForce [
    "pcie-brcmstb" # required for the pcie bus to work
    "reset-raspberrypi" # required for vl805 firmware to load
    "usbhid"
    "usb-storage"
    "vc4"
    "genet" # Pi 4 ethernet
    "mmc_block" # turns the detected SD card into /dev/mmcblk0
  ];

  # The `sd-image-aarch64` module also imports the installer `base`
  # profile, which enables ZFS support by default — compiling the ZFS
  # kernel module against the custom RPi kernel on every rebuild, for
  # nothing.
  boot.supportedFilesystems.zfs = false;

  # This appliance has exactly one SD card slot: mount the root by
  # device.
  fileSystems."/".device = lib.mkForce "/dev/mmcblk0p2";

  # On boot failure, drop to a shell instead of hanging silently.
  boot.kernelParams = [ "boot.shell_on_fail" ];

  # The boot chain above never consults the system profile: the
  # firmware loads a fixed kernel and a fixed `init=` path. Rebuilds
  # must rewrite those files, or every reboot reverts to the
  # generation the SD image was built from. NixOS calls this installer
  # on every `nixos-rebuild switch`/`boot` with the new system path as
  # argument; it replaces the extlinux installer from
  # `sd-image-aarch64`, which wrote an unused menu to /boot.
  system.build.installBootLoader = lib.mkForce (
    pkgs.writeShellScript "update-pi-firmware" ''
      set -eu
      # Mount the firmware partition: the fstab entry exists on every
      # generation, but an older one may still carry `noauto` and an
      # unstarted mount unit, so neither the mount point nor the mount
      # may exist yet.
      mkdir -p /boot/firmware
      mountpoint -q /boot/firmware || mount /boot/firmware
      firmware=/boot/firmware
      system="$1"
      # Copy to a temporary name first: a power cut mid-switch must not
      # leave a truncated kernel on the boot partition.
      cp "$system/kernel" "$firmware/Image.tmp"
      sync
      mv -f "$firmware/Image.tmp" "$firmware/Image"
      cp "$system/initrd" "$firmware/initrd.tmp"
      sync
      mv -f "$firmware/initrd.tmp" "$firmware/initrd"
      printf 'init=%s/init %s\n' "$system" "$(cat "$system/kernel-params")" \
        > "$firmware/cmdline.txt.tmp"
      sync
      mv -f "$firmware/cmdline.txt.tmp" "$firmware/cmdline.txt"
      sync
    ''
  );

  # The installer above writes to the firmware partition, so mount it
  # at runtime instead of `sd-image.nix`'s `noauto` default. Device
  # trees, overlays and GPU boot code are only refreshed by a new SD
  # image — fine while the kernel generation does not change.
  fileSystems."/boot/firmware".options = lib.mkForce [ "nofail" ];

  # ---------------------------------------------------------------------------

  networking.hostName = "morille";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # https://discourse.nixos.org/t/nixos-rebuild-remote-deployments-non-root-pam/50477
  security.pam = {
    # Enable the ssh-agent of a user to be used to authenticate them.
    sshAgentAuth.enable = true;
    # Allow ssh-agent authentication to give authorization to use sudo.
    services.sudo.sshAgentAuth = true;
  };

  # Swap in RAM to avoid wearing out the SD card
  zramSwap.enable = true;

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  # The Raspberry Pi kernel, firmware and boot loader come from the
  # `nixos-hardware` module (see flake.nix).
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
