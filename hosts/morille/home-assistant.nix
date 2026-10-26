# Home Assistant, running in a podman container managed by the
# `podman-home-assistant` systemd service.
# https://www.home-assistant.io/installation/linux
{
  config,
  ...
}:

let
  # Let's Encrypt publishes every issued hostname in the public
  # Certificate Transparency logs anyway, so the domain is not treated
  # as a secret here.
  domain = "reunion.servebeer.com";
in
{
  # Let's Encrypt certificate, renewed automatically by the NixOS ACME
  # module (lego). No-IP hosts cannot use the DNS-01 challenge (no TXT
  # record API), so the HTTP-01 challenge is served by lego itself:
  # port 80 must be forwarded to this machine, and only needs to answer
  # during issuance and renewal. Home Assistant itself is reachable on
  # the router's port mapping 8312 (external) -> 8123 (internal).
  security.acme = {
    acceptTerms = true;
    defaults.email = "contact@thomas-bouvier.io";

    certs."${domain}" = {
      listenHTTP = ":80";
      # Restart Home Assistant when the certificate renews so it picks
      # up the new files.
      reloadServices = [ "podman-home-assistant" ];
    };
  };

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
      "/var/lib/acme/${domain}:/certificates:ro"
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

  # The ACME challenge (HTTP-01), served on port 80 by lego.
  networking.firewall.allowedTCPPorts = [
    80
    8123
  ];
}
