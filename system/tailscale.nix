{ lib, config, ... }:
{
  services.tailscale = {
    enable = true;

    # Keeps locally bridged networks (incusbr0, podman, LAN) out of the
    # exit-node tunnel: without it, replies from local daemons (Incus's
    # dnsmasq) vanish and coi containers lose DNS whenever an exit node
    # is active. No-op on hosts that use no exit node.
    extraSetFlags = [ "--exit-node-allow-lan-access" ];
  };
}
