# Home Assistant, running in a podman container managed by the
# `podman-home-assistant` systemd service.
# https://www.home-assistant.io/installation/linux
{
  config,
  ...
}:

{
  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable";

    # Boot with the cached image: an appliance must be able to start
    # without the network. Update manually:
    #   sudo podman pull ghcr.io/home-assistant/home-assistant:stable
    #   sudo systemctl restart podman-home-assistant
    pull = "missing";

    # Required for Bluetooth support
    privileged = true;

    # Host networking allows Home Assistant to discover devices on the
    # local network (mDNS, SSDP...).
    # `--stop-timeout` gives Home Assistant time to close its database.
    extraOptions = [
      "--network=host"
      "--stop-timeout=60"
    ];

    volumes = [
      "/var/lib/home-assistant:/config"
      "/run/dbus:/run/dbus:ro"
    ];

    environment = {
      TZ = config.time.timeZone;
    };
  };

  # Rootful podman does not create missing bind-mount sources.
  systemd.tmpfiles.rules = [ "d /var/lib/home-assistant 0755 root root - -" ];

  # The Pi has no battery-backed clock: at boot it starts with a stale
  # time until timesyncd corrects it. Pulling the image requires valid
  # TLS, so wait for the clock to be right.
  systemd.services.podman-home-assistant = {
    after = [ "time-sync.target" ];
    wants = [ "time-sync.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];
}
