{ pkgs, ... }:

let
  # Import the user-icons module
  userIconsModule = import ../system/icon.nix;
in
{
  imports = [
    userIconsModule
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.thomas = {
    isNormalUser = true;
    initialPassword = "pw123";
    extraGroups = [
      "wheel"
      "networkmanager"
      "podman"
      "incus-admin" # code-on-incus (coi)
      "systemd-journal" # code-on-incus (coi): kernel-journal access for nft monitoring
    ]; # Enable ‘sudo’ for the user.

    icon = ./thomas/assets/avatar.png;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIwyCOXTY+2S+UlllvyKqU9qx0fyvWICHRiduOR2Kwxx contact@thomas-bouvier.io"
    ];
  };

  # Adding trusted users is required for devenv.
  # Also required to build from a remote device https://nixos.wiki/wiki/Nixos-rebuild.
  # A list of names of users that have additional rights when connecting
  # to the Nix daemon, such as the ability to specify additional binary
  # caches. You can also specify groups by prefixing them with @; for
  # instance, @wheel means all users in the wheel group.
  nix.settings.trusted-users = [
    "root"
    "thomas"
  ];

  # Home-manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";

    users.thomas = import ./thomas;
  };
}
