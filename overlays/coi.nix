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
  version = "0.13.0";
in
{
  coi = final.buildGoModule {
    pname = "code-on-incus";
    inherit version;

    src = final.fetchFromGitHub {
      owner = "coipond";
      repo = "coi";
      rev = "v${version}";
      hash = "sha256-hqzHu9oPk4uE0duISS5KeOIBc6SlJaBkbCSLiu2GHC0=";
    };

    vendorHash = "sha256-XSTbxBrLzHBNLhzCz7aDqZ5ioaQlZgIWexjtpbX9xk0=";

    # Replicates the embedded-asset step of `make build` (upstream Makefile):
    # go:embed cannot use "..", so testdata/dummy/dummy is copied into its
    # package. Since v0.13.0 upstream tracks build.sh and the default config
    # in their embed packages directly, so only the dummy file is generated.
    postPatch = ''
      mkdir -p internal/image/embedded
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
