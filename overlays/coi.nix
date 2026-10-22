# code-on-incus (coi): run AI coding agents inside isolated Incus system
# containers. https://github.com/coipond/coi (repo moved from
# mensfeld/code-on-incus; the old URL still redirects)
#
# Upstream has no Nix packaging and ships cgo binaries linked against
# libsystemd, so we build from source. Version bumps happen here — never
# use `coi update` (self-update rewrites its own binary, impossible under
# the Nix store / the cap wrapper).
final: prev:
let
  version = "0.15.0";
in
{
  coi = final.buildGoModule {
    pname = "code-on-incus";
    inherit version;

    src = final.fetchFromGitHub {
      owner = "coipond";
      repo = "coi";
      rev = "v${version}";
      hash = "sha256-ky+c1qPBqpU4QfenbXOcthcG5yGVLnfRvolDJMR6q1E=";
    };

    vendorHash = "sha256-XSTbxBrLzHBNLhzCz7aDqZ5ioaQlZgIWexjtpbX9xk0=";

    # Replicates the embedded-asset step of `make build` (upstream Makefile):
    # go:embed cannot use "..", so testdata/dummy/dummy is copied into its
    # package. Since v0.13.0 upstream tracks build.sh and the default config
    # in their embed packages directly, so only the dummy file is generated.
    postPatch = ''
      mkdir -p internal/image/embedded
      cp testdata/dummy/dummy internal/image/embedded/dummy

      # build.sh installs opencode from GitHub's releases/latest channel —
      # since v2 that channel only serves the v1 line (v2 ships as git tags,
      # distributed via opencode.ai), so every freshly created coi container
      # would boot opencode v1. Point the image's install at the official v2
      # CLI tarball instead (same archive layout: one `opencode` binary at
      # the archive root, same opencode-linux-<arch> asset naming). The
      # grep guard makes a future upstream URL change fail the build loudly
      # instead of silently shipping v1 images again.
      grep -q 'https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-' internal/image/build.sh \
        || { echo "ERROR: opencode download URL not found in build.sh — upstream changed it, update the sed below" >&2; exit 1; }
      sed -i 's|https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-|https://opencode.ai/update/api/latest/cli/opencode/opencode-linux-|' internal/image/build.sh
    '';

    # coi reads the systemd journal via cgo (internal/nftmonitor/journalctl.go)
    nativeBuildInputs = [ final.pkg-config ];
    buildInputs = [ final.systemdMinimal ];

    ldflags = [
      "-X github.com/coipond/coi/internal/cli.Version=${version}"
    ];

    doCheck = false; # tests require a running Incus

    # go-systemd's sdjournal resolves libsystemd at runtime via
    # dlopen("libsystemd.so.0") — no link-time dependency, so nothing shows up
    # in ldd. NixOS has no global library path, and dlopen searches the calling
    # object's RUNPATH, so add the library there explicitly.
    postFixup = ''
      patchelf --add-rpath ${final.systemdMinimal.out}/lib $out/bin/coi
    '';

    meta = {
      description = "Give each AI agent its own isolated machine with root, Docker, and systemd";
      homepage = "https://github.com/coipond/coi";
      license = final.lib.licenses.mit;
      mainProgram = "coi";
    };
  };
}
