{ ... }:

{
  networking = {
    networkmanager = {
      enable = true;
      # Ensure NetworkManager doesn't override DNS settings
      dns = "systemd-resolved";
    };

    firewall = {
      enable = true;

      # Localsend: port 53317
      # CUPS: port 631
      # mDNS: port 5353
      allowedTCPPorts = [
        53317
        631
      ];
      allowedUDPPorts = [
        53317
        631
        5353
      ];
    };

    extraHosts = "
      144.76.43.250 lix.systems
      144.76.43.250 git.lix.systems
    ";
  };

  services.resolved = {
    enable = true;

    settings.Resolve = {
      DNSOverTLS = false;
      DNSSEC = false;
      DNS = [
        "86.54.11.13"
        "86.54.11.213"
        "2a13:1001::86.54.11.13"
        "2a13:1001::86.54.11.213"
      ];
    };
  };
}
