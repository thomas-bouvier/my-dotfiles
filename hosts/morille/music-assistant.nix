# Music Assistant, running in a podman container managed by the
# `podman-music-assistant` systemd service.
# https://www.music-assistant.io/installation
{
  config,
  ...
}:

{
  virtualisation.oci-containers.containers.music-assistant = {
    image = "ghcr.io/music-assistant/server:latest";

    # Boot with the cached image: an appliance must be able to start
    # without the network. Update manually:
    #   sudo podman pull ghcr.io/music-assistant/server:latest
    #   sudo systemctl restart podman-music-assistant
    pull = "missing";

    # Host networking allows Music Assistant to discover and stream to
    # players on the local network (mDNS, uPnP). Unlike Home Assistant,
    # no privileged mode is needed.
    extraOptions = [
      "--network=host"
    ];

    volumes = [
      "/var/lib/music-assistant:/data"
      # Local music library, read-only:
      # "/path/to/music:/media:ro"
    ];

    environment = {
      TZ = config.time.timeZone;
    };
  };

  # Rootful podman does not create missing bind-mount sources.
  systemd.tmpfiles.rules = [ "d /var/lib/music-assistant 0755 root root - -" ];

  # The Pi has no battery-backed clock: pulling the image requires valid
  # TLS, so wait for the clock to be right.
  systemd.services.podman-music-assistant = {
    after = [ "time-sync.target" ];
    wants = [ "time-sync.target" ];
  };

  networking.firewall = {
    # 8095: web interface and API — players also fetch stream and
    # announcement URLs from it over HTTP.
    # 8097: stream server, players pull the actual audio from it.
    # mDNS (UDP 5353) is already open in `system/networking.nix`, so
    # Home Assistant auto-discovers the server. AirPlay players would
    # additionally need the ephemeral port ranges:
    # https://www.music-assistant.io/faq/networking/
    allowedTCPPorts = [
      8095
      8097
    ];
  };
}
