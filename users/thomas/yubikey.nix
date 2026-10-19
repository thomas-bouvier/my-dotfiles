# YubiKey tools.
# Requires the system-side module: ../../system/yubikey.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ykman, to configure the YubiKey (slots, FIDO, OATH, PIV...)
    yubikey-manager

    # OATH/TOTP authenticator
    yubioath-flutter
  ];
}
