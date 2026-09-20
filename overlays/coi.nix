# code-on-incus (coi): run AI coding agents inside isolated Incus system
# containers. https://github.com/mensfeld/code-on-incus
#
# Upstream has no Nix packaging and ships cgo binaries linked against
# libsystemd, so we build from source. Version bumps happen here — never
# use `coi update` (self-update rewrites its own binary, impossible under
# the Nix store / the cap wrapper).
final: prev:
let
  version = "0.12.0";
in
{
  coi = final.buildGoModule {
    pname = "code-on-incus";
    inherit version;

    src = final.fetchFromGitHub {
      owner = "mensfeld";
      repo = "code-on-incus";
      rev = "v${version}";
      hash = "sha256-6pyfWhSEfJ2l6dxuf3m6CZuZ5/rohgE5z0QXfOOCIFc=";
    };

    vendorHash = "sha256-C5wY73sM6U5iUYuOxdynsJYbRT+k7KRE7I9aRhwvjT4=";

    # Replicates the embedded-asset step of `make build` (upstream Makefile):
    # go:embed cannot use "..", so these files are copied into their packages.
    postPatch = ''
      mkdir -p internal/image/embedded internal/config/embedded
      cp profiles/default/config.toml internal/config/embedded/default_config.toml
      cp testdata/dummy/dummy internal/image/embedded/dummy
    '';

    # coi reads the systemd journal via cgo (internal/nftmonitor/journalctl.go)
    nativeBuildInputs = [ final.pkg-config ];
    buildInputs = [ final.systemdMinimal ];

    ldflags = [
      "-X github.com/mensfeld/code-on-incus/internal/cli.Version=${version}"
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
      homepage = "https://github.com/mensfeld/code-on-incus";
      license = final.lib.licenses.mit;
      mainProgram = "coi";
    };
  };
}
