# YubiKey tools and GnuPG configuration.
# Requires the system-side module: ../../system/yubikey.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ykman, to configure the YubiKey (slots, FIDO, OATH, OpenPGP...)
    yubikey-manager

    # OATH/TOTP authenticator
    yubioath-flutter
  ];

  programs.gpg = {
    enable = true;

    scdaemonSettings = {
      # Let GnuPG access the YubiKey through pcscd instead of its own
      # CCID driver, so that GnuPG and the OATH app don't fight over it.
      # https://wiki.nixos.org/wiki/Yubikey#Smartcard_mode
      disable-ccid = true;
    };
  };
}
