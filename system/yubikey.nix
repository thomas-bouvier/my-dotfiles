# YubiKey support for all YubiKey applications: OTP, FIDO2 (SSH) and OATH.
# Login/sudo via FIDO (pam_u2f) is deliberately not enabled yet,
# but the udev rules below already support it.
#
# https://wiki.nixos.org/wiki/Yubikey
{ pkgs, ... }:

{
  # USB device permissions
  services.udev.packages = [
    pkgs.yubikey-personalization # OTP/CCID interfaces
    pkgs.libfido2 # FIDO hidraw access, for pam_u2f (login), WebAuthn and
    # FIDO2 SSH keys (ssh-keygen -t ed25519-sk)
  ];

  # PC/SC smartcard daemon, required by the OATH application and ykman
  services.pcscd.enable = true;
}
