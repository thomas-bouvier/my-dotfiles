# Installation instructions

You should probably follow the [NixOS manual](https://nixos.org/manual/nixos/stable/index.html#sec-installation). I share my own notes for reference.

Download the [minimal ISO NixOS image](https://nixos.org/download/), and create a bootable USB drive following the instructions in [Section "Booting from a USB flash drive"](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb) of the NixOS manual.

> [!TIP]
> If installing for an Apple Silicon machine, you should download an ISO from [here](https://github.com/nix-community/nixos-apple-silicon/releases) instead.

> [!NOTE]
> **Raspberry Pi 4 (`morille`)**: the Pi cannot boot the minimal ISO. Instead, build the pre-installed SD card image from an `aarch64` machine (e.g. `amanite`), then flash it to the SD card (**this erases the card**). No installer, no partitioning: the image boots directly into the system and grows the root partition on first boot.
>
> The build snapshots the **git tree**: new files must be tracked (`git add`) before building, or they are invisible to it. Don't keep build inputs as untracked or restrictive-permission files in the repo.
>
> ```console
> nix build .#nixosConfigurations.morille.config.system.build.sdImage
> ```
>
> Identify your SD card with `lsblk` (it should be a `disk`, not a `part`), then flash it — **beware: `of=` must be the full block device path under `/dev/`; without the `/dev/` prefix, `dd` silently writes a regular file into the current directory instead**:
>
> ```console
> zstd -d result/sd-image/*.img.zst --stdout | sudo dd of=/dev/<DISK> bs=4M status=progress conv=fsync
> ```
>
> First boot takes a few minutes (partition resize + Nix store registration) before the machine appears on the network as `morille`. Subsequent boots take well under a minute.
>
> To update the running system, deploy from an `aarch64` machine — with the `ssh-ng://` store type, as the default copy transport hangs against the target:
>
> ```console
> nh os switch . -H morille --target-host ssh-ng://thomas@morille
> ```
>
> Note that the kernel, the initrd and the kernel command line live on the boot partition, which is only written when the image is built: after a lock update that bumps the kernel, rebuild and reflash the SD card image.

Identify your USB stick (the USB stick should not have been mounted):

```console
lsblk
```

Copy the ISO to the USB stick (replace <DISK> with your USB stick, it should be a `disk` not a `part`):

```console
sudo dd if=<ISO_FILE> of=/dev/<DISK> bs=4M status=progress
```

Once in the UEFI menu, make sure that:

- Ensure Safe (Secure) Boot is Disabled.
- Ensure Fast Boot is Disabled.
- Ensure UEFI Mode is Enabled.
- Ensure Boot from USB is Enabled.

Boot the machine from this USB drive.

> [!TIP]
> If installing for an Apple Silicon machine, run the script referenced at https://asahilinux.org/ from macOS. Then, select `Shrink macOS as much as (safely) possible` > `Install an OS into free space` and `UEFI environment only (m1n1 + U-Boot + ESP)`. Name it `NixOS` when asked. Follow these [instructions](https://github.com/nix-community/nixos-apple-silicon/blob/main/docs/uefi-standalone.md).

> [!WARNING]
> If installing for an Apple Silicon machine, during `alx.sh`, take note of the `EFI PARTUUID:`. This will be useful later.

## Once on the live USB

The US layout is chosen by default.

```bash
sudo loadkeys mod-dh-ansi-us
```

For other layouts like French or German, use `loadkeys fr` or `loadkeys de`.

We'll enable internet access before partitioning. Just run `nmtui`.

Alternatively, use `wpa_supplicant` like that:

```bash
sudo systemctl start wpa_supplicant
wpa_cli
add_network
set_network 0 ssid ""
set_network 0 psk ""
set_network 0 key_mgmt WPA-PSK
enable_network 0
quit
```

Or `iwd`, if previous programs are not available:

```bash
iwctl
device list
station <name> get-networks
station <name> connect <ssid>
exit
```

## Partitioning

### Manual partitioning

I recommend using the Disko partioning approach detailed in the next section instead of partitioning manually.

Once in the NixOS shell, identify the name of your system disk by using the `lsblk` command as follows:

```console
lsblk
```

The output from this command will look something like this:

```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
nvme0n1     259:0    0   1,8T  0 disk
```

> [!WARNING]
> If installing for an Apple Silicon machine, read [this](https://github.com/nix-community/nixos-apple-silicon/blob/main/docs/uefi-standalone.md#partitioning-and-formatting) instead. Different steps may apply.

We'll use `fdisk` to partition the disk:

```console
sudo fdisk /dev/nvme0n1
```

You can hit `m` to list available commands.

Create partitions and swapfile: a [useful video](https://youtu.be/axOxLJ4BWmY?si=rQWfBgPNd2M-YcjC&t=291) for this step.

### Disko partitioning

Once in the NixOS shell, identify the name of your system disk by using the `lsblk` command as follows:

```console
lsblk
```

The output from this command will look something like this:

```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
nvme0n1     259:0    0   1,8T  0 disk
```

In this example, an empty NVME SSD with 2TB space is shown with the disk name
`nvme0n1`. Make a note of the disk name as you will need it later.

Let us adapt a templated Disko configuration at `/tmp/disko-configuration.nix`. Download
a base config from one of the following locations using the `-o` option to save the file as
`disko-configuration.nix`:

```bash
# To reuse the configuration of the cladosporium host (LUKS + btrfs)
curl https://raw.githubusercontent.com/thomas-bouvier/my-dotfiles/main/hosts/cladosporium/disko-configuration.nix -o /tmp/disko-configuration.nix
# To reuse the configuration of the golmotte host (Apple Silicon + btrfs)
curl https://raw.githubusercontent.com/thomas-bouvier/my-dotfiles/main/hosts/golmotte/disko-configuration.nix -o /tmp/disko-configuration.nix

# Alternatively, use upstream Disko config (btfrs)
curl https://raw.githubusercontent.com/nix-community/disko/master/example/btrfs-subvolumes.nix -o /tmp/disko-configuration.nix
# Upstream Disko config (LUKS + btrfs)
curl https://raw.githubusercontent.com/nix-community/disko/master/example/luks-btrfs-subvolumes.nix -o /tmp/disko-configuration.nix
```

> [!WARNING]
> Be careful if you prepare an Apple Silicon machine. You should not touch any of the partitions created by `alx.sh`. Honestly this is a bit tricky. The risk is to have to DFU restore the machine if you mess with the existing UUIDs.

Inside the `disko-configuration.nix` the device needs to point to the correct disk name (adjust the `device` if needed). Open the configuration in your favorite editor i.e.:

```bash
vim /tmp/disko-configuration.nix
```

Replace `<disk-name>` with the name of your disk obtained earlier.

```nix
# ...
main = {
  type = "disk";
  device = "<disk-name>";
  content = {
    type = "gpt";
# ...
```

> [!WARNING]
> Extra work is needed for Apple Silicon machines as one should not mess up what `alx.sh` has done for us. The following commands apply to Apple Silicon machines only.

Apple Silicon users: stop and read [this](https://github.com/nix-community/nixos-apple-silicon/blob/main/docs/uefi-standalone.md#partitioning-and-formatting). One should not damage the GPT partition table, first partition (`iBootSystemContainer`), or the last partition (`RecoveryOSContainer`) otherwise we'll end up making the machine unbootable.

Let us use `ls -l /dev/disk/by-partuuid/` to match up the existing partitions' UUIDs. The `uuid = "<partuuid>"` attribute of [all macOS-related partitions](https://github.com/thomas-bouvier/my-dotfiles/blob/bc47489e182d067c73e192140d91381a4268e6be/hosts/golmotte/disko-configuration.nix#L19-L56) should be set manually. In particular, the EFI UUID MUST match the `alx.sh` output we obtained at the very beginning of this README.

Apple Silicon or not, if you used LUKS, set a LUKS password in `/tmp/secret.key`:

```bash
echo password > /tmp/secret.key
```

The following step will partition and format your disk, and mount it to `/mnt`.

**Please note: This will erase any existing data on your disk.**

```bash
# Non-Apple Silicon machine
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount /tmp/disko-configuration.nix

# Apple Silicon machine
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode format,mount /tmp/disko-configuration.nix
```

You should see a confirmation input and several output lines around partitioning and formatting the disks (see below), and don’t worry if you receive an error (for instance you forgot to add the password file) because one can re-run disko multiple times. If you are uncertain about the outcome, you can always check the disko command’s return with `echo $?` (should be `0`):

```console
[..]
+ mountpoint=
+ type=btrfs
+ findmnt /dev/mapper/nixos /mnt/nix
+ mount /dev/mapper/nixos /mnt/nix -o compress=zstd -o noatime -o ssd -o space_cache=v2 -o user_subvol_rm_allowed -o subvol=@nix -o X-mount.mkdir
+ rm -rf /tmp/nix-shell-2791-0/tmp.jzrZ2yCjqz

$ echo $?
0
```

After the command has run, your filesystem should have been formatted and mounted. You can verify this by running the following command:

```bash
mount | grep /mnt
```

The output should look like this if your disk name is `nvme0n1`.

```
/dev/nvme0n1p1 on /mnt type ext4 (rw,relatime,stripe=2)
/dev/nvme0n1p2 on /mnt/boot type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro)
```

## Apple Silicon machine

Copy the peripheral firmware files off the EFI system partition (e.g. on the installation ISO `mkdir -p /mnt/etc/nixos/firmware && cp /mnt/boot/asahi/{all_firmware.tar.gz,kernelcache*} /mnt/etc/nixos/firmware`).

## First NixOS installation

Your disks have now been formatted and mounted, and you are ready to complete
the NixOS installation as described in the
[NixOS manual](https://nixos.org/manual/nixos/stable/index.html#sec-installation) -
see the section headed "**Installing**", Steps 3 onwards. 

### You did not use Disko

Generate the configuration files `configuration.nix` and `hardware-configuration.nix` as follows:

```console
sudo nixos-generate-config --root /mnt
```

You can then edit the produced configuration:

```console
ls /mnt/etc/nixos
vim /mnt/etc/nixos/configuration.nix
```

You can now edit `configuration.nix` as per your requirements. Set an `initialPassword` for your user, set a hostname, install `git`, configure a wifi backend.

> [!WARNING]
> Additional steps are [needed](https://github.com/nix-community/nixos-apple-silicon/blob/main/docs/uefi-standalone.md#nixos-configuration) for Apple Silicon machines. The `apple-silicon-support` module should be imported. Also, specify the path to peripheral firmware files as follows: `hardware.asahi.peripheralFirmwareDirectory = ./firmware;`.

Once you are done with a configuration, install the new machine as follows:

```console
sudo nixos-install
reboot
```

### You used Disko

You will need
to include the partitioning and formatting configurations that you copied into
`/tmp/disko-configuration.nix` in your configuration, rather than allowing NixOS to
generate information about your file systems. When you are configuring the
system as per Step 4 of the manual, you should:

Include the `no-filesystems` switch when using the `nixos-generate-config`
command to generate an initial `configuration.nix`. You will be supplying the
file system configuration details from the `disko-configuration.nix` we prepared earlier. Your CLI command to
generate the configuration will be:

```console
sudo nixos-generate-config --no-filesystems --root /mnt
```

This will create the file `configuration.nix` in `/mnt/etc/nixos`. Move the `disko` configuration to `/etc/nixos`:

```console
mv /tmp/disko-configuration.nix /mnt/etc/nixos
```

You can now edit `configuration.nix` as per your requirements. Set an `initialPassword` for your user, set a hostname, install `git`, configure a wifi backend.

As we used Disko, one need to add the `disko` NixOS
module and `disko-configuration.nix` to the imports section. This section will already
include the file `./hardware-configuration.nix`, and you can add the new entries
just below this. This section will now include:

```nix
imports =
 [ # Include the results of the hardware scan.
   ./hardware-configuration.nix
   "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
   ./disko-configuration.nix
 ];
```

> [!WARNING]
> Additional steps are [needed](https://github.com/nix-community/nixos-apple-silicon/blob/main/docs/uefi-standalone.md#nixos-configuration) for Apple Silicon machines. The `apple-silicon-support` module should be imported. Also, specify the path to peripheral firmware files as follows: `hardware.asahi.peripheralFirmwareDirectory = ./firmware;`.

Once you are done with a configuration, install the new machine as follows:

```console
sudo nixos-install
reboot
```

> [!WARNING]
> **Apple Silicon swap fix:** If your disko configuration includes a swap file
> (e.g. `swap.swapfile`), it will be formatted by `mkswap` in the installer
> environment, which uses a different kernel page size than the installed Asahi
> kernel (4K vs 16K). Swap will silently fail to activate on first boot.
>
> After rebooting into your new system, reformat the swap file:
>
> ```
> nix-shell -p util-linux --run "sudo mkswap /.swapfile/swapfile"
> sudo swapon /.swapfile/swapfile
> ```
>
> Verify with `swapon --show`. This only needs to be done once.

## Complete installation

Once logged in in NixOS, clone this repository `git clone git@github.com:thomas-bouvier/my-dotfiles.git` at the location of your choice `<current_config>` and follow steps documented in [README.md](README.md).

If you use an Apple Silicon machine, don't forget to copy firmware file `firmware.cpio` to the current configuration `cp /etc/nixos/firmware/* <current_config>/hosts/<host>/firmware/`. Actually, please also backup them in an external location.

> [!IMPORTANT]
> My configuration uses Lix, but our fresh NixOS
> install ships with stock Nix. The two handle flake lock files differently,
> so the first rebuild requires re-locking the Lix inputs:
>
> ```
> nix --experimental-features "nix-command flakes" flake lock --update-input lix --update-input lix-module
> ```
>
> After the first successful rebuild, Lix replaces stock Nix and this step
> is no longer needed.
>
> Do not commit the modified `flake.lock` back to the repo as it would
> break machines already running Lix. Discard the change after the first
> rebuild:
>
> ```
> git checkout flake.lock
> ```
