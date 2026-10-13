# YubiKey support for all YubiKey applications: OTP, OpenPGP (GPG/SSH)
# and OATH. Login/sudo via FIDO (pam_u2f) is deliberately not enabled yet,
# but the udev rules below already support it.
#
# https://wiki.nixos.org/wiki/Yubikey
{ pkgs, ... }:

{
  # USB device permissions
  services.udev.packages = [
    pkgs.yubikey-personalization # OTP/CCID interfaces
    pkgs.libu2f-host # FIDO hidraw access, for pam_u2f (login) and WebAuthn
  ];

  # PC/SC smartcard daemon, required by the OpenPGP and OATH applications
  services.pcscd.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-qt; # graphical passphrase prompt on Plasma
  };
}
