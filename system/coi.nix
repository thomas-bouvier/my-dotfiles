{ pkgs, ... }:

{
  # Incus daemon + client CLI. The module also creates the incus-admin group
  # and root subordinate UID/GID ranges (idmap) needed for unprivileged
  # containers, and loads the veth/bridge kernel modules.
  virtualisation.incus = {
    enable = true;

    # Declarative replacement for `incus admin init`: managed bridge, CoW
    # storage pool (btrfs loopback; ZFS is not available on the Asahi kernel)
    # and the default profile. Re-applied at each activation.
    preseed = {
      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          config = {
            "ipv4.address" = "10.100.100.1/24";
            "ipv4.nat" = "true";
            "ipv6.address" = "none";
          };
        }
      ];
      storage_pools = [
        {
          name = "default";
          driver = "btrfs";
          config.size = "50GiB"; # sparse loopback file under /var/lib/incus/disks/
        }
      ];
      profiles = [
        {
          name = "default";
          devices = {
            root = {
              type = "disk";
              path = "/";
              pool = "default";
            };
            eth0 = {
              type = "nic";
              name = "eth0";
              network = "incusbr0";
            };
          };
        }
      ];
    };
  };

  # Required by the Incus module (unsupported with the iptables backend) and
  # by coi's nftables-based network isolation. coi creates its own
  # "ip filter" nft table idempotently, coexisting with the NixOS ruleset.
  networking.nftables.enable = true;

  # Incus's dnsmasq listens on the bridge IP (10.100.100.1) for DHCP (UDP 67)
  # and DNS (TCP/UDP 53). The firewall input policy is drop and an accept in
  # Incus's own nft table cannot override it (verdicts don't cross tables),
  # so without this rule containers never get an IPv4 address.
  networking.firewall.interfaces.incusbr0 = {
    allowedUDPPorts = [
      53
      67
    ];
    allowedTCPPorts = [ 53 ];
  };

  # coi invokes `sudo -n nft ...` in restricted/allowlist network modes.
  # NixOS sudo has no secure_path, so `sudo nft` resolves via the user's PATH;
  # the rule targets the stable system-profile path so it survives upgrades.
  environment.systemPackages = [ pkgs.nftables ];
  security.sudo.extraRules = [
    {
      users = [ "thomas" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nft";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # coi applies chattr +i on host-side protected paths (defense-in-depth);
  # file capabilities cannot live in the Nix store, so grant it via a wrapper.
  # /run/wrappers/bin precedes the system profile in PATH.
  security.wrappers.coi = {
    source = "${pkgs.coi}/bin/coi";
    owner = "root";
    group = "root";
    capabilities = "cap_linux_immutable=ep";
  };

  # Keep NetworkManager from enrolling container veths into firewall zones
  # (coi issue #695).
  networking.networkmanager.unmanaged = [ "interface-name:veth*" ];
}
